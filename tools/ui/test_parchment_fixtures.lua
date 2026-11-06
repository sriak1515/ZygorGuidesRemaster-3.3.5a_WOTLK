-- Exercise the shipped client fixture with the real parser, row status model,
-- step completion engine and presentation partition. No live player state.
local root=arg[1] or "ZygorGuidesViewerRM"
tinsert,tremove=table.insert,table.remove
function TableKeys(t) local out={} for k in pairs(t or {}) do out[#out+1]=k end return out end
local L=setmetatable({coords="%s,%s",stepgoal_use="Use %s"},{__index=function(_,key) return key end})
function ZygorGuidesViewer_L() return L end
local level,faction=1,"Alliance"
UnitLevel=function() return level end
UnitRace=function() return "Human","Human" end
UnitClass=function() return "Warrior","WARRIOR" end
UnitFactionGroup=function() return faction end
GetRealZoneText=function() return "Elwynn Forest" end
GetItemCount=function() return 0 end
QUEST_MONSTERS_KILLED="%s slain: %d/%d"
SlashCmdList={}
ZygorGuidesViewer={L=L,LM={},BZL={},BSZL={},BFL={},StandingNamesEngRev={},dailyQuests={},instantQuests={},
    db={profile={skipobsolete=true,showobsolete=true},char={}},recentlyCompletedGoals={},recentlyStickiedGoals={},
    registeredguides={}}
local ZGV=ZygorGuidesViewer
function ZGV:GetQuestName() return nil end
function ZGV:RaceClassMatch() return true end
function ZGV:RegisterGuide(title,raw)
    self.registeredguides[#self.registeredguides+1]={title=title,raw=raw}
end
function ZGV:UpdateFrame() self.refreshes=(self.refreshes or 0)+1 end
assert(loadfile(root.."/Goal.lua"))()
assert(loadfile(root.."/Step.lua"))()
assert(loadfile(root.."/Parser.lua"))()
assert(loadfile(root.."/Parchment.lua"))()
assert(loadfile(root.."/Guides/Tests/ParchmentFixtures.lua"))()
assert(#ZGV.registeredguides==1,"fixture registration must not select or add campaign guides")
assert(not ZGV.CurrentGuide,"loading fixtures changed the active guide")
local fixture=ZGV.registeredguides[1]
local guide,err,line=ZGV:ParseEntry(fixture.raw)
assert(guide,tostring(err).." at "..tostring(line))
assert(#guide.steps==11,"fixture index changed: update the documented comparison cases")
assert(not guide.defaultfor and not guide.next,"fixture became a default or campaign continuation")
local P=ZGV.Parchment
local expected={
    {2,1,false},{4,7,false},{4,0,false},{0,2,true},{4,1,false},
    {3,1,false},{32,2,false},{0,13,true},{2,1,false},{2,2,false},{2,1,false},
}
local function snapshot(step)
    local actions,context,story,confirms=P:Partition(step,false)
    return table.concat({#actions,#context,tostring(story),#confirms},":"),actions,context,story,confirms
end
for n,step in ipairs(guide.steps) do
    local value,actions,context,story,confirms=snapshot(step)
    local want=expected[n]
    assert(#actions==want[1] and #context==want[2] and story==want[3],step.title.." partition changed: "..value)
    local spacers=0
    for _,g in ipairs(step.goals) do if P:IsEmptyInfo(g) then spacers=spacers+1 end end
    assert(#actions+#context+(story and #confirms or 0)+spacers==#step.goals,step.title.." lost nonempty rows")
    local done,possible=step:IsComplete()
    assert(not done and possible,step.title.." is not stable while waiting for manual navigation")
    for _,g in ipairs(step.goals) do
        assert(not g.questid and not g.x and not g.autoscript,"core fixtures must not depend on quests, navigation or automatic scripts")
        if n<=10 then assert(not g.useitemid,"core fixture requires inventory") end
    end
    -- None of the core screenshots should depend on level/faction/quest history.
    level,faction=80,"Horde"
    assert(snapshot(step)==value,"player state changed fixture "..n)
    level,faction=1,"Alliance"
end
local empty=guide.steps[9].goals[1]
assert(P:IsEmptyInfo(empty),"empty legacy spacer was rendered as content")
empty.tooltip="A meaningful attached direction"
assert(not P:IsEmptyInfo(empty),"empty-info rule discarded a tooltip")
empty.tooltip=nil
empty.icon="Interface\\Icons\\INV_Misc_QuestionMark"
assert(not P:IsEmptyInfo(empty),"empty-info rule discarded an icon")
empty.icon=nil
local complete=guide.steps[5]
assert(complete.goals[1]:GetStatus()=="complete" and complete.goals[3]:GetStatus()=="complete")
assert(complete.goals[2]:GetStatus()=="incomplete" and complete.goals[4]:GetStatus()=="incomplete")
ZGV.recentlyStickiedGoals[complete.goals[2]]=true
assert(complete.goals[2]:GetStatus()=="complete","manual completion path is unavailable")
ZGV.recentlyStickiedGoals={}
assert(guide.steps[7].goals[32].text:find("Objective 32",1,true))
local token=guide.steps[10].goals[1]
assert(token.script=="ZygorGuidesViewer:ParchmentFixtureUseToken()" and token.buttonicon)
assert(token:GetStatus()=="incomplete")
ZGV:ParchmentFixtureUseToken()
assert(token:GetStatus()=="complete" and ZGV.refreshes==1,"harmless action failed to update completion")
assert(not guide.steps[10]:IsComplete(),"inline activation advanced past its guard row")
local selected,selectedStep
function ZGV:SetGuide(title,n) selected,selectedStep=title,n end
function ZGV:Print(value) self.lastMessage=value end
SlashCmdList.ZGVPARCHMENTFIXTURE("reset")
assert(selected==fixture.title and selectedStep==1 and not ZGV.ParchmentFixtureTokenUsed)
local settings=P:Settings()
settings.x,settings.y=123,234
ZGV.db.profile.windowlocked=true;ZGV.db.profile.framescale=0.8
SlashCmdList.ZGVPARCHMENTFIXTURE("baseline")
assert(settings.width==380 and settings.height==520 and settings.split==0.55)
assert(not settings.tools and not settings.collapsed and not settings.plaincontext)
assert(settings.x==123 and settings.y==234 and ZGV.db.profile.windowlocked and ZGV.db.profile.framescale==0.8,"fixture preset moved or rescaled the user's UI")
for n=1,11 do SlashCmdList.ZGVPARCHMENTFIXTURE(tostring(n));assert(selectedStep==n) end
local last=selectedStep
SlashCmdList.ZGVPARCHMENTFIXTURE("12")
assert(selectedStep==last and ZGV.lastMessage,"invalid fixture index changed selection")
local item=guide.steps[11].goals[1]
assert(item.action=="use" and item.useitemid==159,"optional native item fixture lost its real item path")
print("PASS: 11 client fixtures parse, retain all rows, hold stable states across player profiles, show fixed completion, exceed 20 rows, and preserve harmless inline/native item paths")
