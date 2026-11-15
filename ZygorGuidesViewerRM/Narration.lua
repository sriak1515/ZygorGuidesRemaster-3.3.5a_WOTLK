-- Lightweight Guide Format v1 narration reader.
--
-- Narration metadata is a presentation sidecar. It never registers a guide,
-- completes a goal, changes navigation, or authorizes guide entry. The native
-- Zygor guide remains fully independent when this module or the consumer is
-- absent, rejects malformed data, or cannot draw a frame.
local ZGV = ZygorGuidesViewer
if not ZGV then return end

local N = {}
ZGV.CampaignNarration = N

local pairs,ipairs,next,type,tostring,tonumber = pairs,ipairs,next,type,tostring,tonumber
local tinsert,tsort = table.insert,table.sort
local floor,huge = math.floor,math.huge
local upper = string.upper

local registry = {}       -- native registration -> record
local byGuideId = {}      -- authored guide id -> record
local currentChar         -- identity of the per-character delivery store
local ui                  -- lazily created reader
local readerEntry         -- entry currently shown
local readerRecord        -- record currently shown
local autoOpen = false

local MAX_STEPS = 10000
local MAX_GOALS = 100000
local MAX_PASSAGES = 4096
local MAX_TEXT = 65536
local MAX_TITLE = 512
local MAX_ID = 256
local MAX_DEPTH = 16
local MAX_CONDITION_NODES = 512

local function isInteger(value,max)
	return type(value)=='number' and value==value and value~=huge and value~=-huge
		and value==floor(value) and value>=1 and (not max or value<=max)
end

local function isText(value,max)
	return type(value)=='string' and #value>0 and #value<=(max or MAX_TEXT)
end

local function isHash(value)
	return type(value)=='string' and #value==64 and not value:find('[^0-9a-f]')
end

local function isArray(value,max)
	if type(value)~='table' or getmetatable(value) then return false end
	local count=0
	for key in pairs(value) do
		if type(key)~='number' or not isInteger(key,max) then return false end
		count=count+1
	end
	for index=1,count do if value[index]==nil then return false end end
	return true
end

local function allowedFields(value,list)
	if type(value)~='table' or getmetatable(value) then return false end
	local allowed={}
	for name in list:gmatch('%S+') do allowed[name]=true end
	for key in pairs(value) do
		if type(key)~='string' or not allowed[key] then return false end
	end
	return true
end

local function copyCondition(value,depth,budget)
	if type(value)~='table' or getmetatable(value) then return nil end
	if depth>MAX_DEPTH then return nil end
	budget.n=budget.n+1
	if budget.n>MAX_CONDITION_NODES then return nil end
	local key,child=next(value)
	if key==nil or next(value,key)~=nil or type(key)~='string' then return nil end

	if key=='all' or key=='any' then
		if not isArray(child,64) or #child==0 then return nil end
		local out={}
		for index,value2 in ipairs(child) do
			local copied=copyCondition(value2,depth+1,budget)
			if not copied then return nil end
			out[index]=copied
		end
		return {[key]=out}
	elseif key=='not' then
		local copied=copyCondition(child,depth+1,budget)
		if not copied then return nil end
		return {['not']=copied}
	elseif key=='quest_active' or key=='quest_rewarded' then
		if not isInteger(child,2147483647) then return nil end
		return {[key]=child}
	elseif key=='quest_objective_complete' then
		if not allowedFields(child,'quest_id objective_index') then return nil end
		if not isInteger(child.quest_id,2147483647) or not isInteger(child.objective_index,100) then return nil end
		return {quest_objective_complete={quest_id=child.quest_id,objective_index=child.objective_index}}
	elseif key=='has_item' then
		if not allowedFields(child,'item_id count') then return nil end
		if not isInteger(child.item_id,2147483647) or not isInteger(child.count,1000000) then return nil end
		return {has_item={item_id=child.item_id,count=child.count}}
	elseif key=='level_at_least' then
		if not allowedFields(child,'actor level') or child.actor~='leader' then return nil end
		if not isInteger(child.level,80) then return nil end
		return {level_at_least={actor='leader',level=child.level}}
	elseif key=='class_is' then
		if type(child)~='string' then return nil end
		if not (' Warrior Paladin Hunter Rogue Priest DeathKnight Shaman Mage Warlock Druid '):find(' '..child..' ',1,true) then return nil end
		return {class_is=child}
	elseif key=='race_is' then
		if type(child)~='string' then return nil end
		if not (' Human Orc Dwarf NightElf Undead Tauren Gnome Troll BloodElf Draenei '):find(' '..child..' ',1,true) then return nil end
		return {race_is=child}
	end
	return nil
end

local function buildRecord(metadata)
	if type(metadata)~='table' or getmetatable(metadata) then return nil,'invalid-data' end
	if not allowedFields(metadata,'interface_version source_format_version guide native_views narration checkpoints source_locations provenance') then
		return nil,'unknown-field'
	end
	if metadata.interface_version~=1 or metadata.source_format_version~=1 then
		return nil,'unsupported-version'
	end
	if not allowedFields(metadata.guide,'id title') then return nil,'invalid-guide' end
	if not isText(metadata.guide.id,MAX_ID) or not isText(metadata.guide.title,MAX_TITLE) then
		return nil,'invalid-guide'
	end
	if metadata.checkpoints~=nil and not isArray(metadata.checkpoints,MAX_PASSAGES) then
		return nil,'invalid-checkpoints'
	end
	if metadata.provenance~=nil and type(metadata.provenance)~='table' then
		return nil,'invalid-provenance'
	end
	if not isArray(metadata.native_views,10) or #metadata.native_views~=1 then
		return nil,'unsupported-view-count'
	end

	local view=metadata.native_views[1]
	if not allowedFields(view,'registration payload_sha256 steps goals') then return nil,'invalid-view' end
	if not isText(view.registration,MAX_TITLE) or not isHash(view.payload_sha256) then
		return nil,'invalid-view'
	end
	if not isArray(view.steps,MAX_STEPS) or #view.steps==0 then return nil,'invalid-steps' end
	if not isArray(view.goals,MAX_GOALS) then return nil,'invalid-goals' end

	local steps,labels={},{}
	for index,mapping in ipairs(view.steps) do
		if not allowedFields(mapping,'source_step_id source_path native_parts') then return nil,'invalid-step' end
		if not isText(mapping.source_step_id,MAX_ID) or steps[mapping.source_step_id] then
			return nil,'duplicate-step'
		end
		if not isText(mapping.source_path,MAX_ID) then return nil,'invalid-step' end
		if not isArray(mapping.native_parts,8) or #mapping.native_parts==0 then return nil,'invalid-step' end
		steps[mapping.source_step_id]=true
		for _,label in ipairs(mapping.native_parts) do
			if not isText(label,MAX_ID) or labels[label] then return nil,'duplicate-label' end
			labels[label]=mapping.source_step_id
		end
		if mapping.source_path~='/steps/'..(index-1) then return nil,'invalid-step-path' end
	end

	for _,goal in ipairs(view.goals) do
		if not allowedFields(goal,'source_path source_step_id native_label native_goal_index native_support_indices action quest_id npc_id objective_index count source_goal_id item_id object_id to') then
			return nil,'invalid-goal'
		end
		if not isText(goal.source_step_id,MAX_ID) or not steps[goal.source_step_id] then return nil,'invalid-goal' end
		if not isText(goal.native_label,MAX_ID) or labels[goal.native_label]~=goal.source_step_id then
			return nil,'invalid-goal-label'
		end
		if not isInteger(goal.native_goal_index,1000) then return nil,'invalid-goal' end
		if goal.native_support_indices~=nil and not isArray(goal.native_support_indices,1000) then
			return nil,'invalid-goal'
		end
		for _,key in ipairs({'quest_id','npc_id','objective_index','count','item_id','object_id'}) do
			if goal[key]~=nil and not isInteger(goal[key],2147483647) then return nil,'invalid-goal' end
		end
	end

	local locations
	if metadata.source_locations~=nil then
		if not isArray(metadata.source_locations,MAX_STEPS) then return nil,'invalid-locations' end
		locations={}
		for _,mapping in ipairs(metadata.source_locations) do
			if not allowedFields(mapping,'source_step_id goals') or not isText(mapping.source_step_id,MAX_ID)
				or not steps[mapping.source_step_id] or locations[mapping.source_step_id]
				or not isArray(mapping.goals,1000) then
				return nil,'invalid-locations'
			end
			locations[mapping.source_step_id]=true
			for _,goal in ipairs(mapping.goals) do
				if not allowedFields(goal,'source_path location') or not isText(goal.source_path,MAX_ID)
					or not allowedFields(goal.location,'zone x y radius show_waypoint hint')
					or not isText(goal.location.zone,MAX_TITLE) then
					return nil,'invalid-locations'
				end
				for _,key in ipairs({'x','y'}) do
					local value=goal.location[key]
					if value~=nil and (type(value)~='number' or value<0 or value>100) then return nil,'invalid-locations' end
				end
				if (goal.location.x==nil)~=(goal.location.y==nil) then return nil,'invalid-locations' end
				if goal.location.show_waypoint~=nil and type(goal.location.show_waypoint)~='boolean' then return nil,'invalid-locations' end
			end
		end
	end

	if not isArray(metadata.narration,MAX_PASSAGES) then return nil,'invalid-narration' end
	local passages,byId={},{}
	for index,passage in ipairs(metadata.narration) do
		if not allowedFields(passage,'id type at_step text requires thread_id purpose title revision source_order source_path') then
			return nil,'invalid-passage'
		end
		if not isText(passage.id,MAX_ID) or byId[passage.id] then return nil,'duplicate-passage' end
		if passage.type~='context' and passage.type~='moment' and passage.type~='chapter' then
			return nil,'invalid-passage'
		end
		if not isText(passage.at_step,MAX_ID) or not steps[passage.at_step] then return nil,'unknown-anchor' end
		if not isText(passage.text,MAX_TEXT) or not isHash(passage.revision) then return nil,'invalid-passage' end
		for _,key in ipairs({'thread_id','purpose','title'}) do
			if passage[key]~=nil and not isText(passage[key],MAX_TITLE) then return nil,'invalid-passage' end
		end
		if passage.source_order~=nil and passage.source_order~=index then return nil,'invalid-passage' end
		if passage.source_path~=nil and passage.source_path~='/narration/'..(index-1) then
			return nil,'invalid-passage'
		end
		local requires
		if passage.requires~=nil then
			requires=copyCondition(passage.requires,0,{n=0})
			if not requires then return nil,'invalid-condition' end
		end
		local copied={
			id=passage.id,type=passage.type,at_step=passage.at_step,text=passage.text,
			title=passage.title,purpose=passage.purpose,thread_id=passage.thread_id,
			requires=requires,revision=passage.revision,source_order=index,
			source_path=passage.source_path,
		}
		passages[index]=copied
		byId[passage.id]=copied
	end

	local record={
		guide_id=metadata.guide.id,
		title=metadata.guide.title,
		registration=view.registration,
		steps=labels,
		source_steps=steps,
		passages=passages,
		by_id=byId,
		by_anchor={},
	}
	for _,passage in ipairs(passages) do
		local list=record.by_anchor[passage.at_step]
		if not list then list={}; record.by_anchor[passage.at_step]=list end
		list[#list+1]=passage
	end
	return record
end

local function ensureCharacter()
	local char=ZGV.db and ZGV.db.char
	if char~=currentChar then
		currentChar=char
		readerEntry,readerRecord=nil,nil
		if type(ui)=='table' and ui.reader then ui.reader:Hide() end
	end
	return char
end

local function repairState(state)
	if type(state.anchors)~='table' then state.anchors={} end
	if type(state.pending)~='table' then state.pending={} end
	if type(state.delivered)~='table' then state.delivered={} end
	for key,value in pairs(state.anchors) do
		if type(key)~='string' or value~=true then state.anchors[key]=nil end
	end
	for id,revision in pairs(state.pending) do
		if type(id)~='string' or type(revision)~='string' then state.pending[id]=nil end
	end
	for id,revision in pairs(state.delivered) do
		if type(id)~='string' or type(revision)~='string' then state.delivered[id]=nil end
	end
	return state
end

local function stateFor(record,create)
	local char=ensureCharacter()
	if not char then return nil end
	local root=char.campaignNarration
	if type(root)~='table' then
		if not create then return nil end
		root={version=1,guides={}}
		char.campaignNarration=root
	end
	if root.version~=1 or type(root.guides)~='table' then
		if not create then return nil end
		root={version=1,guides={}}
		char.campaignNarration=root
	end
	local state=root.guides[record.guide_id]
	if type(state)~='table' then
		if not create then return nil end
		state={anchors={},pending={},delivered={}}
		root.guides[record.guide_id]=state
	end
	return repairState(state)
end

local function call(fn,...)
	if type(fn)~='function' then return nil end
	local ok,first,second,third=pcall(fn,...)
	if ok then return first,second,third end
	return nil
end

local function evaluate(condition)
	if condition==nil then return true end
	local key,value=next(condition)
	if key=='not' then
		local result=evaluate(value)
		if result~=nil then return not result end
	elseif key=='all' or key=='any' then
		local unknown=false
		for _,child in ipairs(value) do
			local result=evaluate(child)
			if key=='all' and result==false then return false end
			if key=='any' and result==true then return true end
			if result==nil then unknown=true end
		end
		if not unknown then return key=='all' end
	elseif key=='quest_rewarded' then
		local completed=ZGV.completedQuests
		if type(completed)=='table' and (completed[value] or completed[tostring(value)]) then return true end
		if ZGV.quest_query_complete_received==true then return false end
	elseif key=='quest_active' then
		if ZGV.questLogInitialized==true and type(ZGV.questsbyid)=='table' then
			return ZGV.questsbyid[value]~=nil
		end
	elseif key=='quest_objective_complete' then
		local quest=ZGV.questsbyid and ZGV.questsbyid[value.quest_id]
		local goal=quest and quest.goals and quest.goals[value.objective_index]
		if goal and type(goal.num)=='number' and type(goal.needed)=='number' and goal.needed>0 then
			return goal.num>=goal.needed
		end
	elseif key=='has_item' then
		local count=call(GetItemCount,value.item_id,false)
		if type(count)=='number' and count>=0 then return count>=value.count end
	elseif key=='level_at_least' then
		local level=call(UnitLevel,'player')
		if type(level)=='number' and level>=1 and level<=80 then return level>=value.level end
	elseif key=='class_is' then
		local _,tag=call(UnitClass,'player')
		if type(tag)=='string' then return tag==upper(value) end
	elseif key=='race_is' then
		local _,tag=call(UnitRace,'player')
		if tag=='Scourge' then tag='Undead' end
		if type(tag)=='string' then return tag==value end
	end
	return nil
end

local function ordered(record,state)
	local list={}
	for _,passage in ipairs(record.passages) do
		local status
		if state.delivered[passage.id]~=nil then
			if state.delivered[passage.id]==passage.revision then status='delivered' end
		elseif state.pending[passage.id]==passage.revision then
			status='pending'
		end
		if status then
			list[#list+1]={passage=passage,status=status}
		end
	end
	tsort(list,function(a,b)
		local ao,bo=a.passage.source_order or 0,b.passage.source_order or 0
		if ao~=bo then return ao<bo end
		return a.passage.id<b.passage.id
	end)
	return list
end

local function entryFor(record,item)
	local passage=item.passage
	return {
		registration=record.registration,
		guide_id=record.guide_id,
		id=passage.id,
		revision=passage.revision,
		type=passage.type,
		at_step=passage.at_step,
		title=passage.title,
		text=passage.text,
		source_order=passage.source_order,
		status=item.status,
	}
end

local function evaluateRecord(record,state)
	local added=0
	for _,passage in ipairs(record.passages) do
		if state.anchors[passage.at_step]
			and state.delivered[passage.id]==nil
			and state.pending[passage.id]==nil then
			local reveal=evaluate(passage.requires)
			if reveal==true then
				state.pending[passage.id]=passage.revision
				added=added+1
			end
		end
	end
	return added
end

local function prune(state,record)
	for id,revision in pairs(state.pending) do
		local passage=record.by_id[id]
		if not passage or passage.revision~=revision then state.pending[id]=nil end
	end
	for id,revision in pairs(state.delivered) do
		local passage=record.by_id[id]
		if not passage or passage.revision~=revision then state.delivered[id]=nil end
	end
end

local function currentRecord()
	local name=ZGV.CurrentGuideName or (ZGV.CurrentGuide and ZGV.CurrentGuide.title)
	return name and registry[name] or nil
end

local function firstPending(record,state)
	for _,item in ipairs(ordered(record,state)) do
		if item.status=='pending' then return entryFor(record,item) end
	end
	return nil
end

local function latestDelivered(record,state)
	local list=ordered(record,state)
	for index=#list,1,-1 do
		if list[index].status=='delivered' then return entryFor(record,list[index]) end
	end
	return nil
end

local function makeWidget(kind,parent)
	if type(CreateFrame)~='function' then return nil end
	local ok,frame=pcall(CreateFrame,kind,nil,parent or UIParent)
	if not ok then return nil end
	return frame
end

local function fontPath()
	local font=GameFontNormal and GameFontNormal.GetFont and call(GameFontNormal.GetFont,GameFontNormal)
	return font or STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF'
end

local function addText(parent,size,y)
	local text=parent:CreateFontString(nil,'ARTWORK')
	if not text then return nil end
	text:SetFont(fontPath(),size or 12)
	text:SetPoint('TOPLEFT',parent,'TOPLEFT',16,y or -16)
	text:SetPoint('TOPRIGHT',parent,'TOPRIGHT',-16,y or -16)
	text:SetJustifyH('LEFT')
	return text
end

local function addButton(parent,label,x,y,width,callback)
	local button=makeWidget('Button',parent)
	if not button then return nil end
	button:SetSize(width or 70,20)
	button:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
	if button.SetBackdrop then
		button:SetBackdrop({bgFile='Interface\\Buttons\\white8x8',edgeFile='Interface\\Buttons\\white8x8',tile=true,tileSize=8,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
		button:SetBackdropColor(0.12,0.12,0.14,0.95)
		button:SetBackdropBorderColor(0.45,0.38,0.22,1)
	end
	local text=button:CreateFontString(nil,'ARTWORK')
	if text then
		text:SetFont(fontPath(),12)
		text:SetPoint('CENTER',button,'CENTER',0,0)
		text:SetText(label)
		button.label=text
	end
	button:SetScript('OnClick',function() callback() end)
	return button
end

local function ensureUI()
	if ui==false then return nil end
	if type(ui)=='table' then return ui end
	if type(CreateFrame)~='function' or not UIParent then
		ui=false
		return nil
	end
	-- The cue belongs to the viewer frame. Do not permanently anchor it to
	-- UIParent if metadata loads before AceAddon OnInitialize has assigned it.
	if not ZGV.Frame then return nil end
	local ok,cue,reader=pcall(function()
		local cue=makeWidget('Button',ZGV.Frame or UIParent)
		if not cue then error('cue') end
		cue:SetSize(64,20)
		cue:SetPoint('TOPRIGHT',ZGV.Frame or UIParent,'TOPRIGHT',-4,4)
		if cue.SetBackdrop then
			cue:SetBackdrop({bgFile='Interface\\Buttons\\white8x8',edgeFile='Interface\\Buttons\\white8x8',tile=true,tileSize=8,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
			cue:SetBackdropColor(0.05,0.05,0.07,0.90)
			cue:SetBackdropBorderColor(0.45,0.38,0.22,1)
		end
		local label=cue:CreateFontString(nil,'ARTWORK')
		if not label then error('label') end
		label:SetFont(fontPath(),12)
		label:SetPoint('CENTER',cue,'CENTER',0,0)
		label:SetText('Story')
		cue.label=label
		cue:RegisterForClicks('LeftButtonUp','RightButtonUp')
		cue:SetScript('OnClick',function(_,button)
			if type(InCombatLockdown)=='function' and InCombatLockdown() then return end
			if button=='RightButton' then N:OpenHistory() else N:OpenLatest() end
		end)
		cue:Hide()

		local reader=makeWidget('Frame',UIParent)
		if not reader then error('reader') end
		reader:SetSize(420,260)
		reader:SetPoint('CENTER',UIParent,'CENTER',0,60)
		reader:SetFrameStrata('DIALOG')
		reader:SetMovable(true)
		reader:EnableMouse(true)
		reader:SetClampedToScreen(true)
		reader:RegisterForDrag('LeftButton')
		reader:SetScript('OnDragStart',function(self) self:StartMoving() end)
		reader:SetScript('OnDragStop',function(self) self:StopMovingOrSizing() end)
		if reader.SetBackdrop then
			reader:SetBackdrop({bgFile='Interface\\Tooltips\\UI-Tooltip-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=true,tileSize=16,edgeSize=12,insets={left=4,right=4,top=4,bottom=4}})
			reader:SetBackdropColor(0.02,0.03,0.05,0.94)
			reader:SetBackdropBorderColor(0.52,0.42,0.22,1)
		end
		local title=addText(reader,14,-14)
		title:SetJustifyH('LEFT')
		local scroll=makeWidget('ScrollFrame',reader)
		if not scroll then error('scroll') end
		scroll:SetPoint('TOPLEFT',reader,'TOPLEFT',16,-42)
		scroll:SetPoint('BOTTOMRIGHT',reader,'BOTTOMRIGHT',-16,52)
		scroll:EnableMouseWheel(true)
		scroll:SetScript('OnMouseWheel',function(self,delta)
			local range=self.GetVerticalScrollRange and self:GetVerticalScrollRange() or 0
			local offset=self.GetVerticalScroll and self:GetVerticalScroll() or 0
			offset=offset-(delta or 0)*40
			if offset<0 then offset=0 end
			if offset>range then offset=range end
			if self.SetVerticalScroll then self:SetVerticalScroll(offset) end
		end)
		local body=scroll:CreateFontString(nil,'ARTWORK')
		if not body then error('body') end
		body:SetFont(fontPath(),12)
		body:SetPoint('TOPLEFT',scroll,'TOPLEFT',0,0)
		body:SetWidth(388)
		body:SetJustifyH('LEFT')
		body:SetJustifyV('TOP')
		if body.SetSpacing then body:SetSpacing(2) end
		scroll:SetScrollChild(body)
		local close=addButton(reader,'Close',16,-228,60,function() N:Close() end)
		local earlier=addButton(reader,'Earlier',242,-228,70,function() N:Cycle(-1) end)
		local later=addButton(reader,'Later',318,-228,70,function() N:Cycle(1) end)
		reader.title=title
		reader.scroll=scroll
		reader.body=body
		reader.close=close
		reader.earlier=earlier
		reader.later=later
		reader:Hide()
		return cue,reader
	end)
	if not ok then
		ui=false
		return nil
	end
	ui={cue=cue,reader=reader}
	return ui
end

local function showReader(entry,record)
	local widgets=ensureUI()
	if not widgets then return false end
	local reader=widgets.reader
	local ok=pcall(function()
		if reader.title then reader.title:SetText(entry.title or 'Story') end
		if reader.body then reader.body:SetText(entry.text or '') end
		if reader.scroll then
			if reader.scroll.SetVerticalScroll then reader.scroll:SetVerticalScroll(0) end
			if reader.scroll.UpdateScrollChildRect then reader.scroll:UpdateScrollChildRect() end
		end
		reader:Show()
	end)
	if not ok then return false end
	if reader.IsShown and not reader:IsShown() then return false end
	readerEntry,readerRecord=entry,record
	return true
end

local function markPresented(entry,record,state)
	if state.pending[entry.id]==entry.revision then
		state.pending[entry.id]=nil
	end
	state.delivered[entry.id]=entry.revision
end

function N:RefreshCue()
	local widgets=ensureUI()
	if not widgets then return end
	local record=currentRecord()
	local state=record and stateFor(record,false)
	if not record or not state then
		widgets.cue:Hide()
		return
	end
	local list=ordered(record,state)
	if #list==0 then
		widgets.cue:Hide()
		return
	end
	local pending=0
	for _,item in ipairs(list) do
		if item.status=='pending' then pending=pending+1 end
	end
	if widgets.cue.label then
		widgets.cue.label:SetText(pending>0 and ('Story ('..pending..')') or 'Story')
	end
	if widgets.cue.SetWidth then widgets.cue:SetWidth(pending>0 and 88 or 64) end
	widgets.cue:Show()
end

function N:CanAutoPresent()
	if type(InCombatLockdown)=='function' and InCombatLockdown() then return false end
	if type(UnitCastingInfo)=='function' and UnitCastingInfo('player') then return false end
	if type(UnitChannelInfo)=='function' and UnitChannelInfo('player') then return false end
	if type(SpellIsTargeting)=='function' and SpellIsTargeting() then return false end
	if ZGV.Frame and ZGV.Frame.IsVisible and not ZGV.Frame:IsVisible() then return false end
	for _,name in ipairs({'QuestFrame','GossipFrame','LootFrame','MerchantFrame','TaxiFrame','TrainerFrame','TradeFrame'}) do
		local frame=_G[name]
		if frame and frame.IsShown and frame:IsShown() then return false end
	end
	return true
end

function N:MaybeAutoPresent()
	if not autoOpen then return false end
	if readerEntry then return false end
	local record=currentRecord()
	if not record then return false end
	local state=stateFor(record,false)
	if not state then return false end
	local entry=firstPending(record,state)
	if not entry or not self:CanAutoPresent() then return false end
	return self:OpenLatest()
end

function N:Register(metadata)
	local record,code=buildRecord(metadata)
	if not record then
		if ZGV.Debug then ZGV:Debug('Narration metadata rejected: '..tostring(code)) end
		return false,code
	end
	if registry[record.registration] or byGuideId[record.guide_id] then
		return false,'duplicate-definition'
	end
	registry[record.registration]=record
	byGuideId[record.guide_id]=record

	local state=stateFor(record,false)
	if state then
		prune(state,record)
		evaluateRecord(record,state)
	end
	self:RefreshCue()
	return true
end

function N:OnStepFocused(guide,step)
	ensureCharacter()
	local record=currentRecord()
	if readerRecord and readerRecord~=record then self:Close() end
	self:RefreshCue()
end

function N:OnStepCompleted(guide,step,complete)
	if not complete or not guide or not step then return end
	if step.AreRequirementsMet and not step:AreRequirementsMet() then return end
	local record=registry[guide.title]
	if not record then return end
	local source_id=step.label and record.steps[step.label]
	if not source_id or not record.by_anchor[source_id] then return end
	local state=stateFor(record,true)
	if not state or state.anchors[source_id] then return end
	state.anchors[source_id]=true
	evaluateRecord(record,state)
	self:RefreshCue()
	self:MaybeAutoPresent()
end

function N:OnObservations()
	ensureCharacter()
	for _,record in pairs(byGuideId) do
		local state=stateFor(record,false)
		if state then evaluateRecord(record,state) end
	end
	self:RefreshCue()
	self:MaybeAutoPresent()
end

function N:OnCombatEnded()
	self:RefreshCue()
	self:MaybeAutoPresent()
end

function N:GetStatus(registration)
	local record=registration and registry[registration] or currentRecord()
	if not record then return nil end
	local state=stateFor(record,false)
	local status={registration=record.registration,guide_id=record.guide_id,pending=0,delivered=0,anchors=0,passages=#record.passages}
	if state then
		for id in pairs(state.anchors) do status.anchors=status.anchors+1 end
		for _,item in ipairs(ordered(record,state)) do
			if item.status=='pending' then status.pending=status.pending+1
			elseif item.status=='delivered' then status.delivered=status.delivered+1 end
		end
	end
	return status
end

function N:GetEntries(registration)
	local record=registration and registry[registration] or currentRecord()
	if not record then return {} end
	local state=stateFor(record,false)
	if not state then return {} end
	local entries={}
	for _,item in ipairs(ordered(record,state)) do
		entries[#entries+1]=entryFor(record,item)
	end
	return entries
end

function N:GetPendingEntry(registration)
	local record=registration and registry[registration] or currentRecord()
	if not record then return nil end
	local state=stateFor(record,false)
	if not state then return nil end
	return firstPending(record,state)
end

function N:Present(entry)
	if not entry then return false end
	local record=registry[entry.registration]
	if not record then return false end
	local state=stateFor(record,true)
	if not state then return false end
	if not showReader(entry,record) then return false end
	markPresented(entry,record,state)
	self:RefreshCue()
	return true
end

function N:OpenLatest(registration)
	local record=registration and registry[registration] or currentRecord()
	if not record then return nil end
	local state=stateFor(record,false)
	if not state then return nil end
	local entry=firstPending(record,state) or latestDelivered(record,state)
	if entry and self:Present(entry) then return entry end
	return nil
end

function N:OpenHistory(registration)
	local record=registration and registry[registration] or currentRecord()
	if not record then return nil end
	local state=stateFor(record,false)
	if not state then return nil end
	local entry=latestDelivered(record,state) or firstPending(record,state)
	if entry and self:Present(entry) then return entry end
	return nil
end

function N:Cycle(delta)
	if not readerRecord or not readerEntry then return self:OpenLatest() end
	local state=stateFor(readerRecord,false)
	if not state then return nil end
	local list=ordered(readerRecord,state)
	if #list==0 then return nil end
	local index
	for position,item in ipairs(list) do
		if item.passage.id==readerEntry.id then index=position; break end
	end
	index=(index or #list)+((delta or 1)<0 and -1 or 1)
	if index<1 then index=#list end
	if index>#list then index=1 end
	local entry=entryFor(readerRecord,list[index])
	if self:Present(entry) then return entry end
	return nil
end

function N:Close()
	readerEntry,readerRecord=nil,nil
	if type(ui)=='table' and ui.reader then ui.reader:Hide() end
end

function N:GetReaderEntry() return readerEntry end
function N:IsReaderShown()
	return type(ui)=='table' and ui.reader and ui.reader.IsShown and ui.reader:IsShown() or false
end
function N:SetAutoOpen(value) autoOpen=value and true or false end
function N:GetAutoOpen() return autoOpen end
function N:Evaluate(condition)
	if condition~=nil and type(condition)~='table' then return nil end
	return evaluate(condition)
end

function N:ReportHookFailure(kind,err)
	if not ZGV.Debug then return end
	local now=(type(GetTime)=='function' and GetTime()) or 0
	if self._lastHookFailure and now-self._lastHookFailure<30 then return end
	self._lastHookFailure=now
	ZGV:Debug('Narration '..tostring(kind)..' hook failed: '..tostring(err))
end

function ZGV:RegisterCampaignGuideMetadata(metadata)
	local ok,accepted=pcall(N.Register,N,metadata)
	return ok and accepted==true
end

-- Observation is deliberately late in the event order so QuestTracking has
-- already refreshed the real client cache. These handlers never call a quest
-- query and never advance a step.
if type(ZGV.startups)=='table' then
	tinsert(ZGV.startups,function(self)
		if not self.AddEvent then return end
		self:AddEvent('QUEST_LOG_UPDATE',function() N:OnObservations() end)
		self:AddEvent('QUEST_QUERY_COMPLETE',function() N:OnObservations() end)
		self:AddEvent('BAG_UPDATE',function() N:OnObservations() end)
		self:AddEvent('CHAT_MSG_SYSTEM',function() N:OnObservations() end)
		self:AddEvent('PLAYER_REGEN_ENABLED',function() N:OnCombatEnded() end)
	end)
end