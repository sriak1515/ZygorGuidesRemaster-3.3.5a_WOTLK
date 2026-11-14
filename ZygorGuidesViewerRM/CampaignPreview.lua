-- Internal adapter for PR #6's BLOCKED_NOT_INSTALLABLE preview. Never a package
-- acceptance bypass. Policy is an integration input; it is NOT runtime evidence.
local ZGV=ZygorGuidesViewer
if not ZGV then return end
local P={PolicyVersion=1,PolicyStatus='provisional'}
ZGV.CampaignPreview=P
local records,provider={},nil
local session=tostring({})
local function now() return GetTime and GetTime() end
local function call(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b=pcall(fn,...);if ok then return a,b end
end
local function scalar(v) return type(v)=='string' and #v>0 end
local function truth(condition,facts)
    return ZGV.CampaignAdmission.Evaluate(condition,facts)
end
local function proof(g)
    local s=g.source_goal
    if s.type=='accept_quest' then return {any={{quest_active=s.quest_id},{quest_rewarded=s.quest_id}}}
    elseif s.type=='turnin_quest' then return {quest_rewarded=s.quest_id}
    elseif s.type=='kill' then return {any={{quest_rewarded=s.quest_id},{quest_objective_complete={quest_id=s.quest_id,objective_index=s.objective_index}}}}
    elseif s.type=='collect_item' then
        if s.quest_id then return {any={{quest_rewarded=s.quest_id},{quest_objective_complete={quest_id=s.quest_id,objective_index=s.objective_index}}}} end
        return {has_item={item_id=s.item_id,count=s.count}}
    elseif s.type=='wait_until' then return s.condition
    else return s.complete_when end
end
function P:SetEvidenceProvider(callback)
    assert(callback==nil or type(callback)=='function');provider=callback
end
-- Real client observations only: exact five-member identity, connectivity and
-- levels. A requirements document, cached level or party leader is not enough.
function P:Roster(policy)
    if type(policy.roster)~='table' or #policy.roster~=5 then return end
    local raid=call(GetNumRaidMembers)
    local units,mode={},nil
    if type(raid)~='number' or raid<0 or raid~=math.floor(raid) then return end
    if raid>0 then
        if raid~=5 then return end
        mode='raid';for i=1,raid do units[#units+1]='raid'..i end
    else
        if call(GetNumPartyMembers)~=4 then return end
        mode='party';units={'player','party1','party2','party3','party4'}
    end
    local player=call(UnitGUID,'player')
    if not scalar(player) then return end
    local expected,seen,rows,actors={},{},{},{}
    for _,name in ipairs(policy.roster) do if not scalar(name) or expected[name] then return end;expected[name]=true end
    local foundPlayer=false
    for _,unit in ipairs(units) do
        local exists,online=call(UnitExists,unit),call(UnitIsConnected,unit)
        if (exists~=true and exists~=1) or (online~=true and online~=1) then return end
        local name=call(UnitName,unit);local guid=call(UnitGUID,unit);local level=call(UnitLevel,unit)
        if not expected[name] or seen[name] or not scalar(guid) or type(level)~='number' or level~=math.floor(level)
            or seen[guid] or level<(policy.min_level or 18) or level>80 then return end
        if guid==player then foundPlayer=true end
        seen[name]=true;seen[guid]=true;rows[#rows+1]=name..'/'..guid..'/'..level
        actors[#actors+1]={unit=unit,name=name,guid=guid,level=level,player=guid==player}
    end
    if not foundPlayer then return end
    table.sort(rows);return mode..';'..table.concat(rows,';'),actors
end
function P:Evidence(r,names)
    if r.shared.policy.locked then return false end
    local signature=self:Roster(r.shared.policy)
    local time=now()
    if not signature or type(time)~='number' or time~=time or time<0 or time==math.huge or not provider then return false end
    local char=ZGV.db and ZGV.db.char
    local saved=char and char.campaignPreview
    local suspended=type(saved)=='table' and saved.version==1 and type(saved.guides)=='table' and saved.guides[r.metadata.guide.id]
    local request={source_sha256=r.shared.source_sha256,policy_version=P.PolicyVersion,policy_sha256=r.shared.policy_sha256,roster=signature,session=session,registration=r.view.registration,
        suspension_id=type(suspended)=='table' and suspended.id or nil}
    local sample=call(provider,request)
    if type(sample)~='table' or getmetatable(sample) or sample.source_sha256~=request.source_sha256 or sample.roster~=signature
        or sample.policy_version~=P.PolicyVersion or sample.policy_sha256~=r.shared.policy_sha256 or sample.session~=session or type(sample.observed_at)~='number' or sample.observed_at~=sample.observed_at or sample.observed_at<0 or sample.observed_at>time
        or time-sample.observed_at>30 or type(sample.gates)~='table' or getmetatable(sample.gates) then return false end
    for _,name in ipairs(names or {}) do
        local expected=r.shared.policy.gates[name]
        local fact=sample.gates[name]
        if not expected or type(fact)~='table' or getmetatable(fact) or fact.verified~=true or fact.owner~=expected.owner
            or fact.kind~=expected.kind or not scalar(fact.provenance) then return false end
        if expected.kind=='external-checkpoint' and fact.checkpoint_id~=expected.checkpoint_id then return false end
    end
    if self:Roster(r.shared.policy)~=signature then return false end
    return true,signature,sample
end
local function evidenceSnapshot(sample,names)
    local result={}
    for _,name in ipairs(names) do
        local f=sample.gates[name]
        result[name]={owner=f.owner,kind=f.kind,provenance=f.provenance,observed_at=sample.observed_at}
    end
    return result
end
function P:ReturnEvidence(r,sample)
    local record=sample.return_record
    local policy=r.shared.policy
    if type(record)~='table' or getmetatable(record) or record.owner~=policy.return_owner or not scalar(record.provenance)
        or not scalar(record.date) or not scalar(record.safe_location) or type(record.quest_states)~='table' or type(record.levels)~='table'
        or type(record.checkpoints)~='table' or getmetatable(record.quest_states) or getmetatable(record.levels) or getmetatable(record.checkpoints) then return false end
    local signature,actors=self:Roster(policy)
    if signature~=sample.roster then return false end
    for _,actor in ipairs(actors) do
        local name,level=actor.name,actor.level
        if record.levels[name]~=level or type(record.quest_states[name])~='table' or getmetatable(record.quest_states[name]) then return false end
        for _,qid in ipairs(policy.return_quests) do
            local q=record.quest_states[name][qid]
            if type(q)~='table' or getmetatable(q) or type(q.active)~='boolean' or type(q.rewarded)~='boolean' then return false end
            if actor.player then
                local facts=ZGV.CampaignData:PreviewFacts()
                if not facts.known or not facts.known[qid] or not facts.rewards or facts.rewards[qid]~=q.rewarded
                    or (facts.log[qid]~=nil)~=q.active then return false end
            end
        end
    end
    if record.mode=='observed-return' then
        return scalar(policy.return_checkpoint) and record.checkpoints[policy.return_checkpoint]==true and record.observations_verified==true
    elseif record.mode=='safe-fallthrough' then
        if not scalar(record.reason) or record.observations_verified~=false then return false end
        for _,verified in pairs(record.checkpoints) do if verified~=false then return false end end
        return true
    end
    return false
end
function P:CanAccess(guide)
    local r=guide and records[guide.title]
    if not r then return true end
    if r.guide~=guide or r.state~='bound' then return false end
    local policy=r.shared.policy
    local char=ZGV.db and ZGV.db.char
    local root=char and char.campaignPreview
    local phase=type(root)=='table' and root.version==1 and type(root.guides)=='table' and root.guides[r.metadata.guide.id]
    if type(phase)=='table' and (phase.source_sha256~=r.shared.source_sha256 or phase.policy_version~=P.PolicyVersion or phase.policy_sha256~=r.shared.policy_sha256) then return false end
    if r.view.view_index==0 and type(phase)=='table' and phase.source_sha256==r.shared.source_sha256
        and (phase.state=='suspended' or phase.state=='returned') then return false end
    local names=r.view.view_index==0 and policy.entry_gates or policy.return_gates
    local verified,signature,sample=self:Evidence(r,names)
    if type(names)~='table' or #names==0 or not verified then return false end
    if r.view.view_index>0 then
        if not self:ReturnEvidence(r,sample) then return false end
        local char=ZGV.db and ZGV.db.char
        local saved=char and char.campaignPreview
        local rec=type(saved)=='table' and saved.version==1 and type(saved.guides)=='table' and saved.guides[r.metadata.guide.id]
        if type(rec)~='table' or type(rec.pause_evidence)~='table' or not scalar(rec.roster) or type(rec.observed_at)~='number' or not scalar(rec.session) or rec.continuation~=r.view.registration or not scalar(rec.id) or sample.return_record.suspension_id~=rec.id or rec.source_sha256~=r.shared.source_sha256 or rec.policy_version~=P.PolicyVersion or rec.policy_sha256~=r.shared.policy_sha256 or rec.state~='suspended' and rec.state~='returned' then return false end
        local pause=policy.pause
        if not pause then return false end
        for _,name in ipairs(pause.gates) do
            local fact=rec.pause_evidence[name];local expected=policy.gates[name]
            if type(fact)~='table' or fact.owner~=expected.owner or fact.kind~=expected.kind or not scalar(fact.provenance) then return false end
        end
    end
    return true
end
function P:StepState(r,step)
    local condition=r.shared.policy.step_conditions and r.shared.policy.step_conditions[r.source[step]]
    if r.originalVisibility[step] and not condition then return nil end
    if condition then return truth(condition,ZGV.CampaignData:PreviewFacts()) end
    return true
end
function P:StepAllowed(r,step)
    if self:StepState(r,step)==nil then return false end
    local gates=r.shared.policy.step_gates and r.shared.policy.step_gates[r.source[step]]
    return not gates or self:Evidence(r,gates)==true
end
function P:Complete(r,step)
    if self:StepState(r,step)==false then return true end
    local facts=ZGV.CampaignData:PreviewFacts()
    for _,m in ipairs(r.view.goals) do
        if m.source_step_id==r.source[step] then
            local visible=m.source_goal.only_if and truth(m.source_goal.only_if,facts)
            if m.source_goal.only_if and visible==nil then return nil end
            if visible~=false then
                if m.action=='travel' then
                    local g=step.goals[m.native_goal_index]
                    if ZGV.recentlyStickiedGoals and ZGV.recentlyStickiedGoals[g] or not g:IsComplete() then return false end
                else
                    local result=truth(m.proof,facts)
                    if result==nil then return nil elseif result==false then return false end
                end
            end
        end
    end
    return true
end
function P:FocusTarget(guide,num)
    local r=guide and records[guide.title]
    if not r then return true,num end
    if not self:CanAccess(guide) then return false end
    if type(num)~='number' or num<1 or num>#guide.steps then return false end
    for i=1,num do
        local step=guide.steps[i]
        local visible=self:StepState(r,step)
        if visible==nil then return false end
        if visible then
            if not self:StepAllowed(r,step) then return false end
            if i<num then
                local complete=self:Complete(r,step)
                if complete==nil then return false elseif not complete then return true,i end
            end
        end
    end
    while self:StepState(r,guide.steps[num])==false do
        num=num+1
        if num>#guide.steps or not self:StepAllowed(r,guide.steps[num]) then return false end
    end
    return true,num
end
function P:BlockCurrent()
    if not self.suppressed then self.pauseBefore=ZGV.pause;self.frameWasShown=ZGV.Frame and ZGV.Frame:IsShown() end
    ZGV.pause=true;ZGV.fastforward=nil
    self:ClearNavigation()
    if ZGV.Frame and ZGV.Frame.Hide then self.suppressed=true;ZGV.Frame:Hide() end
end
function P:ClearNavigation()
    if ZGV.ConnectedWaypointer and ZGV.ConnectedWaypointer.setwaypoint then ZGV.ConnectedWaypointer.setwaypoint(ZGV,false)
    elseif ZGV.Pointer and ZGV.Pointer.ClearWaypoints then ZGV.Pointer:ClearWaypoints('way');ZGV.Pointer:ClearWaypoints('route') end
end
function P:CanNavigate()
    local r=ZGV.CurrentGuide and records[ZGV.CurrentGuide.title]
    if not r then return true end
    if not self:CanRun() then return false end
    for _,m in ipairs(r.view.goals) do
        if m.source_step_id==r.source[ZGV.CurrentStep] and m.source_goal.only_if and truth(m.source_goal.only_if,ZGV.CampaignData:PreviewFacts())~=true then return false end
    end
    for _,g in ipairs(ZGV.CurrentStep.goals) do if g.action=='goto' and not g.force_noway then return true end end
    return false -- never infer a suppressed NPC/object target from support rows
end
function P:RefreshAccess()
    local r=ZGV.CurrentGuide and records[ZGV.CurrentGuide.title]
    if r and self:CanAccess(ZGV.CurrentGuide) and (r.source[ZGV.CurrentStep] or ZGV.CurrentStep and ZGV.CurrentStep.finish) and self:StepAllowed(r,ZGV.CurrentStep) then
        if self.suppressed and ZGV.Frame and ZGV.Frame.Show then self.suppressed=nil;ZGV.pause=self.pauseBefore;self.pauseBefore=nil;if self.frameWasShown then ZGV.Frame:Show() end;self.frameWasShown=nil end
    elseif r then self:BlockCurrent() end
end
function P:CanRun()
    local guide=ZGV.CurrentGuide;local r=guide and records[guide.title]
    if not r then return true end
    if not self:CanAccess(guide) or not (r.source[ZGV.CurrentStep] or ZGV.CurrentStep and ZGV.CurrentStep.finish) or not self:StepAllowed(r,ZGV.CurrentStep) then
        self:BlockCurrent();return false
    end
    return true
end
function P:BeforeSkip(delta)
    local guide=ZGV.CurrentGuide;local r=guide and records[guide.title]
    if not r then return true end
    if not self:CanRun() then return false end
    if delta>0 and not self:Complete(r,ZGV.CurrentStep) then return false end
    local target=ZGV.CurrentStepNum+delta
    if target>#guide.steps then
        if r.view.view_index==0 and #r.shared.views>1 then
            local pause=r.shared.policy.pause
            if type(pause)~='table' or pause.at_step~=r.source[ZGV.CurrentStep]
                or type(pause.gates)~='table' or #pause.gates==0 or not self:Evidence(r,pause.gates) then
                self:BlockCurrent();return false
            end
            local char=ZGV.db and ZGV.db.char
            if not char then return false end
            if char.campaignPreview==nil then char.campaignPreview={version=1,guides={}} end
            local root=char.campaignPreview
            if type(root)~='table' or root.version~=1 or type(root.guides)~='table' then return false end
            local ok,roster,sample=self:Evidence(r,pause.gates)
            if not ok then return false end
            root.guides[r.metadata.guide.id]={id=ZGV:CampaignPayloadHash(r.shared.source_sha256..r.shared.policy_sha256..roster..sample.observed_at..session),state='suspended',source_sha256=r.shared.source_sha256,policy_version=P.PolicyVersion,policy_sha256=r.shared.policy_sha256,
                roster=roster,observed_at=sample.observed_at,session=session,continuation=r.shared.views[2].view.registration,
                pause_evidence=evidenceSnapshot(sample,pause.gates)}
            self:BlockCurrent()
            if scalar(pause.dispatch_registration) and ZGV:GetGuideByTitle(pause.dispatch_registration) then
                ZGV:SetGuide(pause.dispatch_registration,pause.dispatch_step or 1)
            end
            return false -- no ordinary adjacency or native synthetic finish across the boundary
        end
        return true
    end
    local allowed,clamped=self:FocusTarget(guide,target)
    return allowed and clamped==target
end
function P:OnFocused(guide,step)
    local r=guide and records[guide.title]
    if not r then
        if self.suppressed and ZGV.Frame and ZGV.Frame.Show then self.suppressed=nil;ZGV.pause=self.pauseBefore;self.pauseBefore=nil;if self.frameWasShown then ZGV.Frame:Show() end;self.frameWasShown=nil end
        return
    end
    if not self:CanAccess(guide) then return end
    if self.suppressed and ZGV.Frame and ZGV.Frame.Show then self.suppressed=nil;ZGV.pause=self.pauseBefore;self.pauseBefore=nil;if self.frameWasShown then ZGV.Frame:Show() end;self.frameWasShown=nil end
    local _,roster,sample=self:Evidence(r,r.view.view_index==0 and r.shared.policy.entry_gates or r.shared.policy.return_gates)
    local char=ZGV.db and ZGV.db.char
    if r.view.view_index>0 and char and char.campaignPreview and char.campaignPreview.version==1 then
        local rec=char.campaignPreview.guides[r.metadata.guide.id]
        if rec then
            rec.state='returned';rec.return_roster=roster;rec.return_observed_at=now()
            rec.return_mode=sample.return_record.mode;rec.return_provenance=sample.return_record.provenance
            rec.return_evidence=evidenceSnapshot(sample,r.shared.policy.return_gates)
        end
    end
    local events={}
    for _,passage in ipairs(r.metadata.narration) do
        local id=passage.id
        local p=r.shared.policy.passages and r.shared.policy.passages[id]
        if p and p.view_index==r.view.view_index and p.activation and p.anchor==r.source[step] then
            events[#events+1]={source_step_id=p.anchor,passage_id=id,kind='activation',quest_id=0}
        end
    end
    ZGV.CampaignData:PreviewEncounter(r,events)
    ZGV.CampaignData:RecoverPreview(r)
end
-- Called inside CampaignData's existing native parsing lifecycle.
function P:Bind(r,guide,fail)
    local labels,source={},{}
    for _,step in ipairs(guide.steps or {}) do
        if not step.label or labels[step.label] then fail(r,'preview-label-mismatch');return end
        labels[step.label]=step
    end
    r.originalVisibility={}
    for _,s in ipairs(r.view.steps) do
        local step=labels[s.native_parts[1]]
        if not step then fail(r,'preview-label-mismatch');return end
        source[step]=s.source_step_id;labels[s.native_parts[1]]=nil
        r.originalVisibility[step]=step.condition_visible
    end
    if next(labels) then fail(r,'preview-label-mismatch');return end
    local expected={accept_quest='accept',turnin_quest='turnin',kill='kill',travel='goto',collect_item='condition',wait_until='condition',use_item='condition',interact_object='condition'}
    local mapped={}
    for _,m in ipairs(r.view.goals) do
        local step
        for candidate,id in pairs(source) do if id==m.source_step_id then step=candidate;break end end
        local g=step and step.goals[m.native_goal_index];local s=m.source_goal
        if not g or g.action~=expected[m.action] then fail(r,'preview-goal-mismatch');return end
        mapped[g]=true
        for _,index in ipairs(m.native_support_indices) do
            local support=step.goals[index]
            if not support or support:IsCompleteable() then fail(r,'preview-support-mismatch');return end
            mapped[support]=true
        end
        local support=m.native_support_indices[#m.native_support_indices] and step.goals[m.native_support_indices[#m.native_support_indices]]
        if (m.action=='accept_quest' or m.action=='turnin_quest') and (g.questid~=s.quest_id or not support or support.npcid~=s.npc_id) then fail(r,'preview-contact-mismatch');return end
        if m.action=='kill' and (g.questid~=s.quest_id or g.objnum~=s.objective_index or g.count~=s.count or g.targetid~=s.npc_id) then fail(r,'preview-kill-mismatch');return end
        if m.action=='travel' and (not g.force_complete or g.map~=(ZGV.BZL and ZGV.BZL[s.to.zone] or s.to.zone) or g.x~=s.to.x or g.y~=s.to.y or (s.to.radius and tonumber(g.dist)~=s.to.radius)
            or (g.force_noway and true or false)~=(s.to.show_waypoint==false)) then fail(r,'preview-travel-mismatch');return end
        if m.action=='use_item' and (not support or support.useitemid~=s.item_id or not support.force_nocomplete) then fail(r,'preview-item-mismatch');return end
        if m.action=='interact_object' and (not support or support.targetid~=s.object_id or not support.force_nocomplete) then fail(r,'preview-object-mismatch');return end
        if m.action=='collect_item' and (not support or support.action~='collect' or support.targetid~=s.item_id or support.count~=s.count or not support.force_nocomplete) then fail(r,'preview-collection-mismatch');return end
        if g.action=='condition' then
            g.condition_complete=function()return truth(m.proof,ZGV.CampaignData:PreviewFacts())==true,true end
            g.text=({collect_item='Complete the listed collection.',use_item='Waiting for the item result.',interact_object='Waiting for the interaction result.',wait_until='Waiting for the required state.'})[m.action]
        end
        if s.only_if then
            local original=g.IsComplete
            g.IsComplete=function(self,...)
                if truth(s.only_if,ZGV.CampaignData:PreviewFacts())~=true then return false,true end
                return original(self,...)
            end
            g.condition_visible=function()return truth(s.only_if,ZGV.CampaignData:PreviewFacts())~=false end
        end
    end
    for step in pairs(source) do
        for _,g in ipairs(step.goals) do if not mapped[g] and (g:IsCompleteable() or g.action and g.action~='') then fail(r,'preview-unmapped-goal');return end end
        -- Native false/UNKNOWN step visibility must never auto-skip a preview row.
        step.condition_visible=function()return P:StepState(r,step)~=false end
    end
    r.steps,r.source,r.state=guide.steps,source,'bound'
end
function P:Register(report,policy)
    local C=ZGV.CampaignData
    local tools=C:PreviewTools()
    local ok,data=pcall(tools.copy,report,{}, {n=0,bytes=0},0)
    if not ok then return false,'invalid-preview' end
    local good,config=pcall(tools.copy,policy or {locked=true,policy_version=P.PolicyVersion,provisional=true},{},{n=0,bytes=0},0)
    if not good then return false,'invalid-policy' end
    local validated,shared,list=pcall(function()
        assert(config.policy_version==P.PolicyVersion and config.provisional==true)
        assert(data.preview_format_version==1 and data.status=='BLOCKED_NOT_INSTALLABLE')
        assert(type(data.guide)=='table' and scalar(data.guide.id) and scalar(data.guide.title))
        for name in pairs(data.guide) do assert(name=='id' or name=='title' or name=='requires_checkpoints') end
        if data.guide.requires_checkpoints~=nil then
            assert(tools.array(data.guide.requires_checkpoints))
            local seen={}
            for _,id in ipairs(data.guide.requires_checkpoints) do assert(scalar(id) and not seen[id]);seen[id]=true end
        end
        assert(type(data.provenance)=='table' and tools.hash(data.provenance.source_sha256))
        assert(tools.array(data.views) and #data.views>=1 and #data.views<=2)
        if not config.locked then
            assert(type(config.gates)=='table' and tools.array(config.entry_gates) and #config.entry_gates>0)
            assert(tools.array(config.return_gates) and #config.return_gates>0 and tools.array(config.roster) and #config.roster==5)
            assert(config.source_sha256==data.provenance.source_sha256)
            assert(scalar(config.return_owner) and scalar(config.return_checkpoint) and tools.array(config.return_quests) and #config.return_quests>0)
            for _,q in ipairs(config.return_quests) do assert(type(q)=='number' and q>=1 and q==math.floor(q)) end
        end
        assert(config.locked==nil or type(config.locked)=='boolean')
        assert(config.min_level==nil or type(config.min_level)=='number' and config.min_level>=1 and config.min_level<=80 and config.min_level==math.floor(config.min_level))
        for _,definition in pairs(config.gates or {}) do assert(type(definition)=='table' and scalar(definition.owner) and scalar(definition.kind)) end
        local function gateList(names)
            assert(tools.array(names) and #names>0)
            for _,name in ipairs(names) do assert(type(name)=='string' and config.gates and config.gates[name]) end
        end
        if not config.locked then
            gateList(config.entry_gates);gateList(config.return_gates)
            for _,id in ipairs(data.guide.requires_checkpoints or {}) do
                local found=false
                for _,gate in ipairs(config.entry_gates) do
                    local expected=config.gates[gate]
                    if expected.kind=='external-checkpoint' and expected.checkpoint_id==id then found=true end
                end
                assert(found) -- never weaken a declared predecessor into a generic ready flag
            end
        end
        for _,names in pairs(config.step_gates or {}) do gateList(names) end
        if config.pause then
            assert(type(config.pause)=='table' and scalar(config.pause.at_step));gateList(config.pause.gates)
            assert(config.pause.dispatch_registration==nil or scalar(config.pause.dispatch_registration))
            assert(config.pause.dispatch_step==nil or type(config.pause.dispatch_step)=='number' and config.pause.dispatch_step>=1 and config.pause.dispatch_step==math.floor(config.pause.dispatch_step))
        end
        local function canonical(value)
            if type(value)~='table' then return type(value)..':'..string.format('%q',tostring(value)) end
            local keys,parts={},{}
            for k in pairs(value) do keys[#keys+1]=k end
            table.sort(keys,function(a,b)if type(a)~=type(b)then return type(a)<type(b)end;return a<b end)
            for _,key in ipairs(keys) do parts[#parts+1]=canonical(key)..'='..canonical(value[key]) end
            return '{'..table.concat(parts,';')..'}'
        end
        local policyHash=ZGV:CampaignPayloadHash(canonical({source=data.provenance.source_sha256,policy=config,version=P.PolicyVersion}))
        local metadata={guide=data.guide,narration={},checkpoints={},encounter_sources={},recovery={},runtime_scope_hash=ZGV:CampaignPayloadHash(data.provenance.source_sha256..policyHash)}
        local state={metadata=metadata,policy=config,source_sha256=data.provenance.source_sha256,policy_sha256=policyHash,views={}}
        local allSteps,allPassages,allGoals={}, {}, {}
        local previous=0
        for index,v in ipairs(data.views) do
            assert(v.view_index==index-1 and type(v.native_text)=='string' and tools.hash(v.payload_sha256) and ZGV:CampaignPayloadHash(v.native_text)==v.payload_sha256)
            assert(tools.array(v.source_range) and #v.source_range==2 and v.source_range[1]==previous and v.source_range[2]>previous)
            previous=v.source_range[2]
            assert(tools.array(v.steps) and #v.steps==v.source_range[2]-v.source_range[1] and tools.array(v.goals))
            v.registration='WoW Solo Adventure Preview\\'..data.guide.id..'\\View '..index
            local ids={}
            for i,s in ipairs(v.steps) do
                assert(s.source_path=='/steps/'..(v.source_range[1]+i-1) and tools.array(s.native_parts) and #s.native_parts==1 and scalar(s.source_step_id) and not allSteps[s.source_step_id])
                assert(s.native_parts[1]==s.source_step_id);allSteps[s.source_step_id]=true;ids[s.source_step_id]=true
            end
            for _,m in ipairs(v.goals) do
                local g=m.source_goal
                assert(type(g)=='table' and g.type==m.action and ids[m.source_step_id] and m.native_label==m.source_step_id)
                assert(type(m.native_goal_index)=='number' and m.native_goal_index>=1 and m.native_goal_index==math.floor(m.native_goal_index) and tools.array(m.native_support_indices))
                assert(scalar(m.source_path) and not allGoals[m.source_path]);allGoals[m.source_path]=true
                local seen={}
                for _,n in ipairs(m.native_support_indices) do assert(type(n)=='number' and n>=1 and n<m.native_goal_index and n==math.floor(n) and not seen[n]);seen[n]=true end
                assert(g.role==nil or g.role=='required');assert(not g.sticky)
                assert(({accept_quest=true,turnin_quest=true,kill=true,travel=true,collect_item=true,wait_until=true,use_item=true,interact_object=true})[m.action])
                local function positive(n)assert(type(n)=='number' and n>=1 and n<2147483648 and n==math.floor(n))end
                if g.type=='accept_quest' or g.type=='turnin_quest' or g.type=='kill' then positive(g.quest_id);positive(g.npc_id) end
                if g.type=='kill' then positive(g.count);positive(g.objective_index) end
                if g.type=='collect_item' then positive(g.item_id);positive(g.count);if g.quest_id then positive(g.objective_index) end end
                if g.type=='use_item' then positive(g.item_id) end
                if g.type=='interact_object' then positive(g.object_id) end
                if g.quest_id then positive(g.quest_id) end
                if g.npc_id then positive(g.npc_id) end
                if g.item_id then positive(g.item_id) end
                if g.object_id then positive(g.object_id) end
                if g.count then positive(g.count) end
                if g.type=='travel' then
                    assert(type(g.to)=='table' and scalar(g.to.zone))
                    assert((g.to.x==nil)==(g.to.y==nil))
                    for _,axis in ipairs({'x','y'}) do assert(g.to[axis]==nil or type(g.to[axis])=='number' and g.to[axis]>=0 and g.to[axis]<=100) end
                    assert(g.to.radius==nil or type(g.to.radius)=='number' and g.to.radius>0)
                    assert(g.to.show_waypoint==nil or type(g.to.show_waypoint)=='boolean')
                end
                m.proof=proof(m);if m.action~='travel' then assert(m.proof);tools.predicate(m.proof) end
                if g.only_if~=nil then tools.predicate(g.only_if) end
                m.quest_id=g.quest_id;m.objective_index=g.objective_index;m.count=g.count;m.npc_id=g.npc_id
            end
            assert(tools.array(v.narration) and tools.array(v.checkpoints))
            for _,p in ipairs(v.narration) do
                assert(scalar(p.id) and not allPassages[p.id] and ids[p.at_step] and scalar(p.text) and tools.hash(p.revision) and type(p.source_order)=='number')
                assert(p.type=='context' or p.type=='moment' or p.type=='chapter')
                assert(p.title==nil or scalar(p.title));if p.requires~=nil then tools.predicate(p.requires) end
                allPassages[p.id]=p;metadata.narration[#metadata.narration+1]=p
            end
            for _,checkpoint in ipairs(v.checkpoints) do
                assert(scalar(checkpoint.id) and ids[checkpoint.at_step]);tools.predicate(checkpoint.proof)
                metadata.checkpoints[#metadata.checkpoints+1]=checkpoint
            end
            local r={metadata=metadata,view=v,shared=state,preview=P,state='staged'}
            state.views[index]=r
        end
        table.sort(metadata.narration,function(a,b)return a.source_order<b.source_order end)
        if config.pause then assert(#state.views==2 and config.pause.at_step==state.views[1].view.steps[#state.views[1].view.steps].source_step_id) end
        for step in pairs(config.step_gates or {}) do assert(allSteps[step]) end
        for step,c in pairs(config.step_conditions or {}) do assert(allSteps[step]);tools.predicate(c) end
        for id,rule in pairs(config.passages or {}) do
            local passage=assert(allPassages[id]);assert(rule.anchor==passage.at_step)
            assert(rule.activation==nil or type(rule.activation)=='boolean')
            assert(rule.recover_reward==nil or type(rule.recover_reward)=='boolean')
            assert(type(rule.view_index)=='number' and state.views[rule.view_index+1])
            local belongs=false
            for _,p in ipairs(state.views[rule.view_index+1].view.narration) do if p.id==id then belongs=true end end
            assert(belongs)
            local producers={}
            for _,step in ipairs(rule.producers or {}) do
                local sameView=false
                for _,mapped in ipairs(state.views[rule.view_index+1].view.steps) do if mapped.source_step_id==step then sameView=true end end
                assert(sameView);producers[step]=true
            end
            metadata.encounter_sources[id]=producers
            if rule.recover_reward then
                -- Recovery is explicitly scoped and must contain positive reward
                -- predicates only (AND/OR); NOT/active/level are not catch-up proof.
                local function rewards(c)
                    local k,v=next(c)
                    if k=='quest_rewarded' then return true end
                    if k~='all' and k~='any' then return false end
                    for _,child in ipairs(v) do if not rewards(child) then return false end end
                    return true
                end
                assert(passage.requires and rewards(passage.requires));metadata.recovery[id]=rule.view_index
            end
        end
        return state,state.views
    end)
    if not validated then return false,'invalid-preview-definition' end
    if not C:InstallPreviewRecords(list) then return false,'duplicate-preview' end
    for _,r in ipairs(list) do records[r.view.registration]=r end
    -- Explicit developer integration path only; no TOC/package/auto-selection.
    for _,r in ipairs(list) do ZGV:RegisterGuide(r.view.registration,r.view.native_text) end
    return true
end
