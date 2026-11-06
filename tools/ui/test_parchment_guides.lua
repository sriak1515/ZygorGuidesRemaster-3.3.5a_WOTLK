-- Parse real shipped guides and exercise the presentation partition without
-- pretending to evaluate player-dependent visibility/completion in a client.
local root=arg[1] or "ZygorGuidesViewerRM"
tinsert,tremove=table.insert,table.remove
function TableKeys(t) local r={} for k in pairs(t) do r[#r+1]=k end return r end
function ZygorGuidesViewer_L() return setmetatable({coords="%s,%s"},{__index=function(_,k) return k end}) end
GetRealZoneText=function() return "Elwynn Forest" end
QUEST_MONSTERS_KILLED="%s slain: %d/%d"
STANDARD_TEXT_FONT="client"
SlashCmdList={}
local faction="Alliance"
UnitFactionGroup=function() return faction end
ZygorGuidesViewer={BZL={},BSZL={},BFL={},StandingNamesEngRev={},dailyQuests={},instantQuests={},StepProto_mt={},GoalProto_mt={},IMAGESDIR="",registeredguides={}}
local ZGV=ZygorGuidesViewer
function ZGV:GetQuestName() return nil end
function ZGV:RaceClassMatch() return true end
function ZGV:RegisterGuide(title,metadata,raw)
    self.registeredguides[#self.registeredguides+1]={title=title,raw=raw or metadata}
end
assert(loadfile(root.."/Goal.lua"))()
-- All rows retained here, independently of a live player's race and quest log.
function ZGV.GoalProto:GetStatus() return "passive" end
assert(loadfile(root.."/Parser.lua"))()
assert(loadfile(root.."/Parchment.lua"))()
local P=ZGV.Parchment
local marked=assert(ZGV:ParseEntry("step\n' Keep this exact text |context\naccept A Real Quest##783 |context\n' West road directions\n"))
assert(#marked.steps[1].goals==3)
assert(marked.steps[1].goals[1].text=="Keep this exact text" and marked.steps[1].goals[1].context)
local a,c=P:Partition(marked.steps[1],false)
assert(#a==2 and #c==1 and a[1].action=="accept","context marker hid an objective")
local cols={
 {"Guides/Leveling/ZygorGuidesAlliance.lua","Alliance"},
 {"Guides/Leveling/ZygorGuidesHorde.lua","Horde"},
 {"Guides/Retail/Leveling/ZygorLevelingAllianceWOTLK.lua","Alliance"},
 {"Guides/Retail/Leveling/ZygorLevelingHordeWOTLK.lua","Horde"},
}
local samples={}
local total,failures=0,0
for _,entry in ipairs(cols) do
    ZGV.registeredguides={};faction=entry[2]
    assert(loadfile(root.."/"..entry[1]))()
    for _,guide in ipairs(ZGV.registeredguides) do
        local parsed,err=ZGV:ParseEntry(guide.raw)
        if parsed then
            for n,step in ipairs(parsed.steps) do
                total=total+1
                local acts,ctx=P:Partition(step,false)
                assert(#ctx==0 and #acts==#step.goals,"legacy rows disappeared or were inferred as context")
                local readacts,readctx,story=P:Partition(step,true)
                local count,chars,plain,item=0,0,0,false
                for _,g in ipairs(step.goals) do
                    if g:IsCompleteable() then count=count+1 end
                    chars=chars+#(g.text or g.info or g.quest or g.target or g.npc or g.param or "")+#(g.tooltip or "")
                    if P:IsPlain(g) then plain=plain+1 end
                    if g.useitemid or g.useitem then item=true end
                end
                local sample={file=entry[1],title=guide.title,num=n,rows=#step.goals,objectives=count,chars=chars,plain=plain,item=item,step=step}
                samples[#samples+1]=sample
                if story then assert(#readctx>0 and #readacts==0) end
            end
        else
            failures=failures+1
            print("PARSE LIMITATION: "..guide.title..": "..tostring(err))
        end
    end
end
assert(total>1000,"real guide corpus was not exercised")
local function emit(label,s)
    assert(s,"missing representative "..label)
    print(string.format("SAMPLE %s: %s | %s | step %d | rows=%d objectives=%d text-bytes=%d plain=%d item=%s",label,s.file,s.title,s.num,s.rows,s.objectives,s.chars,s.plain,tostring(s.item)))
end
local short,long,many,item,story,action
for _,s in ipairs(samples) do
 if s.rows>0 and s.objectives>0 and s.chars<120 and not short then short=s end
 if s.plain>0 and s.objectives>0 and (not long or s.chars>long.chars) then long=s end
 if not many or s.objectives>many.objectives then many=s end
 if s.item and not item then item=s end
 if s.plain==s.rows and s.rows>0 and (not story or s.chars>story.chars) then story=s end
 if s.plain==0 and s.objectives>0 and not action then action=s end
end
emit("short",short);emit("long-mixed",long);emit("dense",many);emit("item",item);emit("plain-reading",story);emit("action-only",action)
for _,s in ipairs({short,long,many,item,story,action}) do
    local a,c,isStory=P:Partition(s.step,true)
    -- Single confirm moves to the fixed Continue control only in story mode.
    local confirms=0
    for _,g in ipairs(s.step.goals) do if g.action=="confirm" then confirms=confirms+1 end end
    assert(#a+#c+(isStory and confirms or 0)==#s.step.goals,"representative step lost parsed goals")
end
print(string.format("PASS: %d real parsed steps; %d guide parse limitations; explicit context metadata preserves text and actionable rows",total,failures))
