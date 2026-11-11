-- Real QuestTracking.lua cache/query hooks + story/projection. All client APIs
-- below are doubles: this is a Lua 5.1 simulation, not a WoW client test.
local root=arg[1] or "ZygorGuidesViewerRM"
table.wipe=function(t) for k in pairs(t) do t[k]=nil end end
local now,log,history=10,{},{}
GetTime=function() return now end
GetQuestLogTitle=function(i)
    local q=log[i]
    if q then return q.title,8,nil,0,false,false,q.complete,false,q.id end
end
GetNumQuestLeaderBoards=function() return 0 end
GetQuestsCompleted=function()
    local result={}
    for k,v in pairs(history) do result[k]=v end
    return result
end
ERR_QUEST_COMPLETE_S="%s completed."
CreateFrame=function() return {SetScript=function() end} end
local ZGV={startups={},db={char={},profile={}},recentlyAcceptedQuests={},bandwidth=100,questLogInitialized=true}
ZygorGuidesViewer=ZGV
for _,name in ipairs({"Debug","NewQuestEvent","LostQuestEvent","TryToCompleteStep"}) do ZGV[name]=function() end end
for _,name in ipairs({"QuestTracking.lua","Presentation.lua","BanethilStory.lua"}) do assert(loadfile(root.."/"..name))() end
local function refresh(entries)
    log=entries;now=now+1
    ZGV:QUEST_LOG_UPDATE_QuestTracking()
end
local function absent()
    assert(not ZGV.db.char.banethilStory and not ZGV:GetPresentationSnapshot().context)
end
refresh({});absent()
-- Guide inspection, forced progression and the mutable completion cache are
-- not evidence, even when a native cache poll also occurs.
ZGV.CurrentGuide={title="Future scene",steps={}}
ZGV.CurrentGuideName="future-guide";ZGV.CurrentStepNum=999
ZGV.CurrentStep={goals={},title="A future story"}
ZGV.completedQuests[2561]=true
ZGV.recentlyAcceptedQuests[2561]=true
ZGV:QuestTracking_SafetyPoll();absent()
refresh({{id=2541,title="Earlier quest",complete=1},{id=483,title="Independent quest",complete=1}});absent()
history={[2541]=true,[483]=true}
ZGV:QUEST_QUERY_COMPLETE_QuestTracking();absent()
-- Accepting 2561 in the real cache path is sufficient, before objective credit.
ZGV.Presentation.mode="live"
refresh({{id=2561,title="Localized quest title",complete=nil}})
local record=assert(ZGV.db.char.banethilStory)
assert(record.evidence=="quest-log:2561")
assert(ZGV:GetPresentationSnapshot().context.autoOpen)
local body=ZGV:GetPresentationSnapshot().context.body
-- Abandonment, unrelated progression and repeat notifications cannot erase or
-- duplicate a conversation already observed.
refresh({});refresh({{id=2561,title="Localized quest title",complete=1}})
history={[2561]=true};ZGV:QUEST_QUERY_COMPLETE_QuestTracking()
assert(ZGV.db.char.banethilStory==record)
-- Simulated addon reload: the character SavedVariables record is retained.
assert(loadfile(root.."/Presentation.lua"))()
assert(loadfile(root.."/BanethilStory.lua"))()
local restored=assert(ZGV:GetPresentationSnapshot().context)
assert(restored.body==body and not restored.autoOpen)
-- Character isolation, then recovery for someone who passed this quest before
-- installing the experiment. Only a fresh server response counts.
ZGV.db.char={};ZGV.questsbyid={};absent()
ZGV.completedQuests[2561]=true;absent()
history={};ZGV:QUEST_QUERY_COMPLETE_QuestTracking();absent()
history={[2561]=true};ZGV:QUEST_QUERY_COMPLETE_QuestTracking()
assert(ZGV.db.char.banethilStory.evidence=="quest-query:2561")
assert(ZGV:GetPresentationSnapshot().context.body==body and not ZGV:GetPresentationSnapshot().context.autoOpen)
-- Evidence can be collected with no guide or experimental UI running.
ZGV.db.char={};ZGV.CurrentGuide=nil;ZGV.CurrentStep=nil
refresh({{id=2561,title="Localized quest title"}})
assert(ZGV:GetPresentationSnapshot().context and not ZGV:GetPresentationSnapshot().context.autoOpen)
print("PASS Banethil story: actual quest-cache/query hooks, negative gates, manual-state isolation, acceptance, historical recovery, retention and simulated reload/character isolation")
