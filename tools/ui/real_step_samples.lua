-- Called by the frame harness after its synthetic cases. Parse real source and
-- format with shipped English strings; skip live translation/quest visibility.
return function(root,ZGV)
    local P=ZGV.Parchment
    local locale=assert(io.open(root.."/Localization/enUS.lua","rb")):read("*a")
    for _,key in ipairs({"questtitle","stepgoal_accept","stepgoal_turn in","stepgoal_talk to","stepgoal_at_suff"}) do
        local literal=assert(locale:match('%["'..key..'"%]%s*=%s*("[^\n]-")'))
        ZGV.L[key]=assert(loadstring("return "..literal))()
    end
    ZGV.IMAGESDIR=""
    ZGV.db.char.permaCompletedDailies={}
    function ZGV:IsQuestPossible() return true end
    local registered={}
    function ZGV:RegisterGuide(title,metadata,raw)
        registered[#registered+1]={title=title,raw=raw or metadata}
    end
    local nativeStatus=ZGV.GoalProto.GetStatus
    ZGV.GoalProto.GetStatus=function() return "passive" end
    local function render(entry,index,mode)
        local guide=assert(ZGV:ParseEntry(entry.raw))
        local step=assert(guide.steps[index])
        step.Translate=function() end -- supplied names; no client/server cache here
        local s=P:Settings()
        s.width,s.height,s.tools=340,400,false
        s.objectivesize,s.contextsize,s.plaincontext,s.collapsed=13,14,mode,false
        ZGV.CurrentGuide,ZGV.CurrentStep,ZGV.CurrentStepNum=guide,step,index
        ZGV:UpdateParchment()
        local actions,context=P:Partition(step,mode)
        local function reachable(pane,goals)
            pane.bar:SetValue(pane.range)
            if #goals>0 then assert(pane.rows[#goals]:GetBottom()>=pane:GetBottom(),"real sample final line unreachable") end
            for i,g in ipairs(goals) do
                local row=pane.rows[i]
                assert(row.goal==g,"real sample changed row order")
                assert(row.label:GetHeight()>=row.label:GetStringHeight(),"real sample label was capped")
                if row.tip:IsShown() then assert(row.tip:GetBottom()>=row:GetBottom(),"real sample direction was clipped") end
            end
        end
        reachable(P.action,actions);reachable(P.context,context)
        if not mode then
            assert(not P.context:IsShown() and #actions==#step.goals,"real inline sample relocated prose")
            assert(P.action.range==0,"normal real sample still requires action scrolling at baseline")
        end
        return step,actions,context
    end
    assert(loadfile(root.."/Guides/Retail/Leveling/ZygorLevelingAllianceWOTLK.lua"))()
    local found
    for _,entry in ipairs(registered) do
        if entry.title=="Leveling Guides\\Northrend (69-80)\\Howling Fjord (69-71)" then found=entry end
    end
    local step,actions=render(assert(found),178,false)
    local accepts,turnins=0,0
    for _,g in ipairs(step.goals) do
        if g.action=="accept" then accepts=accepts+1 end
        if g.action=="turnin" then turnins=turnins+1 end
    end
    assert(accepts==4 and turnins==1,"wrong real quest-handoff sample")
    assert(P.action.rows[#actions].label.valueText:find("The Ancient Armor of the Kvaldir",1,true),"real labels were not formatted")
    print("PASS: real Howling Fjord 178, native English labels, turn-in plus four accepts, inline order and baseline accessibility")

    -- Optional private campaign reference: read locally, never bundle/copy it.
    local supplied=os.getenv("ZYGOR_CAMPAIGN_SAMPLE")
    if supplied and supplied~="" then
        registered={};assert(loadfile(supplied))()
        assert(#registered==1,"supply one campaign source")
        local index=tonumber(os.getenv("ZYGOR_CAMPAIGN_SAMPLE_STEP")) or 3
        local step,actions=render(registered[1],index,false)
        assert(P:IsPlain(actions[1]) and actions[2].action=="talk" and actions[3].action=="accept","campaign sample lost its prose-before-action order")
        local _,splitActions,context=render(registered[1],index,true)
        assert(#context==1 and #splitActions==2,"campaign placement preference lost rows")
        print("PASS: local campaign sample, actual prose/talk/accept order, native labels, both placement modes and baseline accessibility")
    end
    ZGV.GoalProto.GetStatus=nativeStatus
end
