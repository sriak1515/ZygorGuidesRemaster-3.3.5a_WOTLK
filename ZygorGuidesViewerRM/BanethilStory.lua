-- One bounded story integration. See docs/experiments/BANETHIL_STORY_TRIGGER_2026-11-11.md.
-- Evidence enters only from fresh native quest-cache/query results, never steps.
local ZGV=ZygorGuidesViewer
if not ZGV then return end
local Story={}
ZGV.BanethilStory=Story
local id="KAL-02/oben-charm-revelation"

function Story:Remember(evidence,live)
    local char=ZGV.db and ZGV.db.char
    if not char or char.banethilStory then return end
    char.banethilStory={version=1,id=id,evidence=evidence}
    -- Historical recovery and reloading stay quiet; live conversation may unfold.
    self.autoOpen=live and ZGV.Presentation and ZGV.Presentation.mode=="live" or false
    if ZGV.Presentation then ZGV.Presentation:Publish() end
end

function Story:ObserveQuestLog(questsbyid)
    if questsbyid[2561] then self:Remember("quest-log:2561",true) end
end

function Story:ObserveCompletedQuests(quests)
    if quests[2561] then self:Remember("quest-query:2561",false) end
end

function Story:Context()
    local char=ZGV.db and ZGV.db.char
    local record=char and char.banethilStory
    if not record or record.version~=1 or record.id~=id then return end
    return {id=id,title="What the charm reveals",persistent=true,autoOpen=self.autoOpen or false,
        body="The charm reveals a way to free Oben, but he regrets what it requires. He asks you to find his soulless body deep in the den and kill it. Then you must use the charm on the fallen body to release his spirit. He sees no other way to escape the Gnarlpine's control."}
end
