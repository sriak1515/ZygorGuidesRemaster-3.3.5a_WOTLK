-- Internal pilot admission, independent of native progression and presentation.
-- nil is UNKNOWN. Only an explicit reader report records presentation; native
-- progression is never changed here.
local ZGV=ZygorGuidesViewer
if not ZGV then return end
local A={}
ZGV.CampaignAdmission=A
local function evaluate(condition,facts)
    if condition==nil then return true end
    local kind,value=next(condition)
    if kind=='not' then
        local result=evaluate(value,facts)
        if result~=nil then return not result end
    elseif kind=='all' or kind=='any' then
        local unknown=false
        for _,child in ipairs(value) do
            local result=evaluate(child,facts)
            if kind=='all' and result==false then return false end
            if kind=='any' and result==true then return true end
            if result==nil then unknown=true end
        end
        if not unknown then return kind=='all' end
    elseif kind=='quest_active' then
        if facts.log and facts.known and facts.known[value] then return facts.log[value]~=nil end
    elseif kind=='quest_rewarded' then
        if facts.rewards then return facts.rewards[value] end
    elseif kind=='quest_objective_complete' then
        local quest=facts.log and facts.log[value.quest_id]
        local goal=quest and quest.goals[value.objective_index]
        if goal and type(goal.num)=='number' and type(goal.needed)=='number' and goal.needed>0 then
            return goal.num>=goal.needed
        end
    elseif kind=='class_is' then
        if facts.player and facts.player.class then return facts.player.class==value end
    elseif kind=='race_is' then
        if facts.player and facts.player.race then return facts.player.race==value end
    elseif kind=='level_at_least' then
        if facts.player and facts.player.level then return facts.player.level>=value.level end
    elseif kind=='has_item' then
        local count=facts.player and facts.player.items and facts.player.items[value.item_id]
        if count~=nil then return count>=value.count end
    end
    -- Missing or unavailable observations remain unknown, including under NOT.
end
A.Evaluate=evaluate
function A.New(metadata,char)
    local controller={}
    local liveEncounters={}
    local function state(create)
        local root=char.campaignAdmission
        if root==nil and create then
            root={version=1,guides={}};char.campaignAdmission=root
        end
        if type(root)~='table' or root.version~=1 or type(root.guides)~='table' then return end
        local guide=root.guides[metadata.guide.id]
        if guide==nil and create then
            guide={passages={},next_order=0};root.guides[metadata.guide.id]=guide
        end
        if type(guide)=='table' and type(guide.passages)=='table' and type(guide.next_order)=='number' and guide.next_order>=0 and guide.next_order<2147483648 and guide.next_order==math.floor(guide.next_order) then return guide end
    end
    local function matching(record,passage)
        if type(record)~='table' or record.revision~=passage.revision or type(record.proof)~='table' then return false end
        local p=record.proof
        return (p.kind=='accept' or p.kind=='kill' or p.kind=='turnin') and type(p.quest_id)=='number'
            and type(p.qualified)=='boolean' and type(p.reward_baseline)=='boolean'
    end
    function controller:Observe(events,facts)
        self:ObserveCheckpoints(facts)
        local saved=state(false)
        local arrivals={}
        -- A fresh matching action is the anchor; selecting/focusing a step is not.
        for _,event in ipairs(events) do
            for _,passage in ipairs(metadata.narration) do
                if passage.at_step==event.source_step_id then
                    local existing=saved and saved.passages[passage.id]
                    if not matching(existing,passage) then
                        saved=state(true)
                        if saved then
                            liveEncounters[passage.id]=passage.revision
                            saved.passages[passage.id]={revision=passage.revision,proof={
                                kind=event.kind,quest_id=event.quest_id,
                                reward_baseline=event.reward_baseline==true,
                                qualified=event.kind~='turnin'}}
                        end
                    end
                end
            end
        end
        if not saved then return arrivals end
        -- Authored order only breaks ties for passages admitted in this observation.
        for _,passage in ipairs(metadata.narration) do
            local record=saved.passages[passage.id]
            if matching(record,passage) then
                local proof=record.proof
                if proof.kind=='turnin' and not proof.qualified then
                    if facts.log and facts.log[proof.quest_id] then
                        -- Retaking a quest cannot confirm an earlier abandonment.
                        saved.passages[passage.id]=nil;record=nil
                    elseif proof.reward_baseline and facts.log and facts.known and facts.known[proof.quest_id] and facts.rewards and facts.rewards[proof.quest_id]==true then
                        proof.qualified=true
                    end
                end
                if record and proof.qualified==true and record.eligible~=true and evaluate(passage.requires,facts)==true then
                    saved.next_order=saved.next_order+1
                    record.eligible=true;record.order=saved.next_order
                    arrivals[#arrivals+1]={id=passage.id,revision=passage.revision,live=liveEncounters[passage.id]==passage.revision}
                end
            end
        end
        return arrivals
    end
    -- Eligible pending delivery is distinct from first-visible presentation/history.
    -- Only admitted prose can cross this internal boundary; editorial data cannot.
    function controller:Collect()
        local result={}
        local saved=state(false)
        if not saved then return result end
        for _,passage in ipairs(metadata.narration) do
            local record=saved.passages[passage.id]
            if matching(record,passage) and record.proof.qualified==true and record.eligible==true and type(record.order)=='number' then
                result[#result+1]={id=passage.id,revision=passage.revision,type=passage.type,
                    title=passage.title,body=passage.text,order=record.order,
                    presented=type(record.presented_order)=='number'}
            end
        end
        table.sort(result,function(a,b)return a.order<b.order end)
        return result
    end
    function controller:MarkPresented(id,revision)
        local saved=state(false)
        if not saved then return false end
        for _,passage in ipairs(metadata.narration) do
            local record=saved.passages[passage.id]
            if passage.id==id and passage.revision==revision and matching(record,passage)
                and record.proof.qualified==true and record.eligible==true then
                if type(record.presented_order)=='number' then return true end
                local n=saved.next_presented or 0
                if type(n)~='number' or n<0 or n>=2147483648 or n~=math.floor(n) then return false end
                saved.next_presented=n+1;record.presented_order=n+1
                return true
            end
        end
        return false
    end
    function controller:History()
        local result={}
        local saved=state(false)
        if not saved then return result end
        for _,entry in ipairs(self:Collect()) do
            if entry.presented then
                entry.order=saved.passages[entry.id].presented_order
                result[#result+1]=entry
            end
        end
        table.sort(result,function(a,b)return a.order<b.order end)
        return result
    end
    local function canonical(value)
        if type(value)~='table' then return type(value)..':'..string.format('%q',tostring(value)) end
        local keys,parts={},{}
        for k in pairs(value) do keys[#keys+1]=k end
        table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
        for _,k in ipairs(keys) do parts[#parts+1]=canonical(k)..'='..canonical(value[k]) end
        return '{'..table.concat(parts,';')..'}'
    end
    local checkpointHashes={}
    local function checkpointRevision(checkpoint)
        if checkpointHashes[checkpoint.id] then return checkpointHashes[checkpoint.id] end
        local revision=ZGV:CampaignPayloadHash(canonical({guide=metadata.guide.id,id=checkpoint.id,
            at_step=checkpoint.at_step,proof=checkpoint.proof}))
        checkpointHashes[checkpoint.id]=revision
        return revision
    end
    function controller:ObserveCheckpoints(facts)
        for _,checkpoint in ipairs(metadata.checkpoints or {}) do
            if evaluate(checkpoint.proof,facts)==true then
                local root=char.campaignCheckpoints
                if root==nil then root={version=1,guides={}};char.campaignCheckpoints=root end
                if type(root)=='table' and root.version==1 and type(root.guides)=='table' then
                    local guide=root.guides[metadata.guide.id]
                    if guide==nil then guide={};root.guides[metadata.guide.id]=guide end
                    if type(guide)=='table' then
                        local revision=checkpointRevision(checkpoint)
                        if type(guide[checkpoint.id])~='table' or guide[checkpoint.id].proof_revision~=revision then
                            guide[checkpoint.id]={proof_revision=revision,verified=true}
                        end
                    end
                end
            end
        end
    end
    function controller:IsCheckpointProven(id)
        local root=char.campaignCheckpoints
        local guide=type(root)=='table' and root.version==1 and type(root.guides)=='table' and root.guides[metadata.guide.id]
        for _,checkpoint in ipairs(metadata.checkpoints or {}) do
            local record=type(guide)=='table' and guide[checkpoint.id]
            if checkpoint.id==id and type(record)=='table' and record.verified==true then
                return record.proof_revision==checkpointRevision(checkpoint)
            end
        end
        return false
    end
    return controller
end
