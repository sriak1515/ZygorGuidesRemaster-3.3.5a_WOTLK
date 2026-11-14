-- Experimental v1 binding foundation. Deliberately does NOT implement the public
-- RegisterCampaignGuideMetadata gate until admission/delivery semantics exist.
-- Definitions stay in this closure, outside presentation snapshots/saved state.
local ZGV=ZygorGuidesViewer
if not ZGV then return end
local C={}
ZGV.CampaignData=C
local registrations,identities={},{}
local function text(v) return type(v)=='string' and #v>0 and #v<=65536 end
local function integer(v) return type(v)=='number' and v>=1 and v==math.floor(v) and v<2147483648 end
local function hash(v) return type(v)=='string' and #v==64 and not v:find('[^0-9a-f]') end
local function array(t)
    if type(t)~='table' then return false end
    local n=0
    for k in pairs(t) do if not integer(k) then return false end;n=n+1 end
    return n==#t and n<=10000
end
local function fields(t,allowed)
    if type(t)~='table' then return false end
    local keys={}
    for key in allowed:gmatch('%S+') do keys[key]=true end
    for k in pairs(t) do if not keys[k] then return false end end
    return true
end
local function clone(value,seen,budget,depth)
    budget.n=budget.n+1
    assert(budget.n<=100000 and depth<=32)
    if type(value)~='table' then
        assert(type(value)=='string' or type(value)=='boolean' or (type(value)=='number' and value==value and math.abs(value)<math.huge))
        if type(value)=='string' then budget.bytes=budget.bytes+#value;assert(budget.bytes<=4194304) end
        return value
    end
    assert(not getmetatable(value) and not seen[value]);seen[value]=true
    local copy={}
    for k,v in pairs(value) do
        assert(type(k)=='string' or type(k)=='number')
        copy[clone(k,seen,budget,depth+1)]=clone(v,seen,budget,depth+1)
    end
    seen[value]=nil
    return copy
end
local function predicate(t)
    assert(type(t)=='table')
    local key,value=next(t);assert(key and next(t,key)==nil)
    if key=='all' or key=='any' then
        assert(array(value) and #value>0)
        for _,v in ipairs(value) do predicate(v) end
    elseif key=='not' then predicate(value)
    elseif key=='quest_active' or key=='quest_rewarded' then assert(integer(value))
    elseif key=='quest_objective_complete' then
        assert(fields(value,' quest_id objective_index ') and integer(value.quest_id) and integer(value.objective_index))
    elseif key=='has_item' then
        assert(fields(value,' item_id count ') and integer(value.item_id) and integer(value.count))
    elseif key=='level_at_least' then
        assert(fields(value,' actor level ') and value.actor=='leader' and integer(value.level) and value.level<=80)
    elseif key=='class_is' then
        assert(type(value)=='string' and (' Warrior Paladin Hunter Rogue Priest DeathKnight Shaman Mage Warlock Druid '):find(' '..value..' ',1,true))
    elseif key=='race_is' then
        assert(type(value)=='string' and (' Human Orc Dwarf NightElf Undead Tauren Gnome Troll BloodElf Draenei '):find(' '..value..' ',1,true))
    else error('predicate') end
end
local actions={accept_quest='accept',turnin_quest='turnin',kill='kill'}
local function validate(m)
    assert(fields(m,' interface_version source_format_version guide native_views narration checkpoints source_locations provenance '))
    assert(m.interface_version==1 and m.source_format_version==1)
    assert(fields(m.guide,' id title ') and text(m.guide.id) and text(m.guide.title))
    assert(array(m.native_views) and #m.native_views==1) -- expansion/multiple-view semantics not established yet
    local view=m.native_views[1]
    assert(fields(view,' registration payload_sha256 steps goals ') and text(view.registration) and hash(view.payload_sha256))
    assert(array(view.steps) and #view.steps>0 and array(view.goals) and #view.goals>0)
    local steps,labels,paths,goalpaths={}, {}, {}, {}
    for i,s in ipairs(view.steps) do
        assert(fields(s,' source_step_id source_path native_parts ') and text(s.source_step_id) and not steps[s.source_step_id])
        assert(s.source_path=='/steps/'..(i-1) and array(s.native_parts) and #s.native_parts==1)
        local label=s.native_parts[1];assert(text(label) and not labels[label])
        steps[s.source_step_id]=label;labels[label]=s.source_step_id;paths[s.source_step_id]=s.source_path
    end
    local indices,ids={},{}
    for _,g in ipairs(view.goals) do
        assert(fields(g,' source_path source_step_id native_label native_goal_index action quest_id npc_id objective_index count source_goal_id '))
        assert(steps[g.source_step_id]==g.native_label and integer(g.native_goal_index) and actions[g.action])
        assert(integer(g.quest_id) and integer(g.npc_id) and type(g.source_path)=='string')
        local prefix=paths[g.source_step_id]..'/goals/'
        local suffix=g.source_path:sub(#prefix+1)
        assert(g.source_path:sub(1,#prefix)==prefix and suffix:match('^%d+$') and not goalpaths[g.source_path])
        goalpaths[g.source_path]=true
        indices[g.native_label]=indices[g.native_label] or {}
        assert(not indices[g.native_label][g.native_goal_index]);indices[g.native_label][g.native_goal_index]=true
        if g.source_goal_id then assert(text(g.source_goal_id) and not ids[g.source_goal_id]);ids[g.source_goal_id]=true end
        if g.action=='kill' then assert(integer(g.objective_index) and integer(g.count))
        else assert(g.objective_index==nil and g.count==nil) end
    end
    assert(array(m.narration) and array(m.checkpoints) and array(m.source_locations))
    local passageids={}
    for i,p in ipairs(m.narration) do
        assert(fields(p,' id type at_step text title requires purpose thread_id revision source_order source_path '))
        assert(text(p.id) and not passageids[p.id] and steps[p.at_step] and text(p.text) and hash(p.revision))
        assert(p.type=='context' or p.type=='moment' or p.type=='chapter')
        assert(p.source_order==i and p.source_path=='/narration/'..(i-1))
        for _,k in ipairs({'title','purpose','thread_id'}) do assert(p[k]==nil or text(p[k])) end
        if p.requires~=nil then predicate(p.requires) end
        passageids[p.id]=true
    end
    local checkpointids={}
    for _,p in ipairs(m.checkpoints) do
        assert(fields(p,' id at_step proof summary ') and text(p.id) and not checkpointids[p.id] and steps[p.at_step])
        assert(p.summary==nil or text(p.summary));predicate(p.proof);checkpointids[p.id]=true
    end
    local locations={}
    for _,s in ipairs(m.source_locations) do
        assert(fields(s,' source_step_id goals ') and steps[s.source_step_id] and not locations[s.source_step_id] and array(s.goals))
        locations[s.source_step_id]=true
        local seen={}
        for _,g in ipairs(s.goals) do
            assert(fields(g,' source_path location ') and goalpaths[g.source_path] and not seen[g.source_path])
            assert(g.source_path:sub(1,#paths[s.source_step_id]+7)==paths[s.source_step_id]..'/goals/')
            seen[g.source_path]=true
            local l=g.location
            assert(fields(l,' zone x y radius show_waypoint hint ') and text(l.zone))
            assert((l.x==nil)==(l.y==nil))
            for _,k in ipairs({'x','y'}) do assert(l[k]==nil or (type(l[k])=='number' and l[k]>=0 and l[k]<=100)) end
            assert(l.radius==nil or (type(l.radius)=='number' and l.radius>0))
            assert(l.show_waypoint==nil or type(l.show_waypoint)=='boolean');assert(l.hint==nil or text(l.hint))
        end
    end
    local p=m.provenance
    assert(fields(p,' compiler_version compiler_sha256 source_revision source_worktree source_sha256 schema_sha256 source_contract_sha256 target_viewer_revision '))
    for _,k in ipairs({'compiler_sha256','source_sha256','schema_sha256','source_contract_sha256'}) do assert(hash(p[k])) end
    assert(text(p.compiler_version) and text(p.source_revision) and text(p.target_viewer_revision) and type(p.source_worktree)=='boolean')
    return view
end
-- Internal staging only; not a claim that interface-v1 narrative semantics ship.
function C:Stage(metadata)
    local ok,m=pcall(clone,metadata,{}, {n=0,bytes=0},0)
    if not ok then return false,'invalid-data' end
    local valid,view=pcall(validate,m)
    if not valid then return false,'invalid-definition' end
    if identities[m.guide.id] or registrations[view.registration] then return false,'duplicate-definition' end
    for _,guide in ipairs(ZGV.registeredguides or {}) do
        if guide.title==view.registration then return false,'registration-already-exists' end
    end
    local record={metadata=m,view=view,state='staged'}
    identities[m.guide.id]=record;registrations[view.registration]=record
    return true
end
local function fail(record,code)
    record.state,record.code,record.steps,record.source='inactive',code,nil,nil
end
function C:OnRegistered(guide)
    local r=registrations[guide.title];if not r then return end
    if r.guide and r.guide~=guide then fail(r,'duplicate-registration');return end
    r.guide=guide
    if type(guide.rawdata)~='string' or ZGV:CampaignPayloadHash(guide.rawdata)~=r.view.payload_sha256 then fail(r,'payload-mismatch');return end
    if r.state~='inactive' then r.state='registered' end
end
function C:OnParsed(guide)
    local r=registrations[guide.title];if not r or r.state=='inactive' then return end
    if r.guide~=guide or not guide.parsed or type(guide.steps)~='table' then fail(r,'registration-mismatch');return end
    if r.steps==guide.steps then return end
    local labels,source={},{}
    for _,step in ipairs(guide.steps) do
        -- Zygor appends its own unlabelled completion step after the final goal.
        if step.label then
            if labels[step.label] then fail(r,'duplicate-label');return end
            labels[step.label]=step
        elseif not step.finish then fail(r,'missing-label');return end
    end
    local previous=0
    for _,s in ipairs(r.view.steps) do
        local step=labels[s.native_parts[1]]
        if not step or not step.num or step.num<=previous then fail(r,'step-mismatch');return end
        source[step]=s.source_step_id;previous=step.num;labels[step.label]=nil
    end
    if next(labels) then fail(r,'extra-label');return end
    local mapped={}
    for _,g in ipairs(r.view.goals) do
        local step
        for candidate,id in pairs(source) do if id==g.source_step_id then step=candidate;break end end
        local goal=step and step.goals and step.goals[g.native_goal_index]
        if not goal or goal.action~=actions[g.action] or goal.questid~=g.quest_id then fail(r,'goal-mismatch');return end
        mapped[goal]=true
        if g.action=='kill' then
            if goal.objnum~=g.objective_index or goal.count~=g.count or goal.targetid~=g.npc_id then fail(r,'goal-mismatch');return end
        else
            local contact=step.goals[g.native_goal_index-1]
            if not contact or contact.action~='talk' or contact.npcid~=g.npc_id or not contact.force_nocomplete then fail(r,'contact-mismatch');return end
        end
    end
    for step in pairs(source) do
        for _,goal in ipairs(step.goals) do
            if (goal.action=='accept' or goal.action=='turnin' or goal.action=='kill') and not mapped[goal] then
                fail(r,'unmapped-goal');return
            end
        end
    end
    r.steps,r.source,r.state=guide.steps,source,'bound'
end
-- Detached, spoiler-safe inspection; never return definitions, IDs or passage counts.
function ZGV:GetCampaignGuideStatus(registration)
    local r=registrations[registration]
    return r and {state=r.state,code=r.code,delivery='not-implemented'} or nil
end
local observers={}
function C:SubscribeAdvancement(callback)
    assert(type(callback)=='function')
    observers[callback]=true
    return function() observers[callback]=nil end
end
-- Observation before native SkipStep discards the old anchor. This is ONLY a
-- candidate: completion caches/manual marks do not constitute narrative proof.
function C:BeforeAdvance(guide,step,complete,direction)
    local r=guide and registrations[guide.title]
    if not r or r.state~='bound' or r.guide~=guide or r.steps~=guide.steps or not r.source[step] then return end
    local marked=false
    for _,goal in ipairs(step.goals or {}) do
        if ZGV.recentlyStickiedGoals and ZGV.recentlyStickiedGoals[goal] then marked=true end
    end
    for callback in pairs(observers) do
        pcall(callback,{source_step_id=r.source[step],native_label=step.label,
            native_step=step.num,reason=complete and 'native-complete' or 'policy-skip',
            direction=direction,manual_mark=marked,authorizes_story=false})
    end
end
