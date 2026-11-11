-- Already-played Ban'ethil presentation ONLY. No guide/quest/event registration.
-- Prose reused from wow-solo-adventure's Ban'ethil UX model at 632a224.
local ZGV=ZygorGuidesViewer
local P=ZGV.Presentation
local request={id="oben-request",title="Oben Rageclaw",body="You find Oben Rageclaw in the den. He explains that Gnarlpine shamans have separated his spirit from his body. They have enchanted the body and are using it to attack anyone exploring Ban'ethil. Oben is trapped in the Emerald Dream, unable to stop them. He asks you to obtain one of the shamans' voodoo charms so he can study the enchantment and find a way to free himself."}
local revelation={id="oben-revelation",title="What the charm reveals",body="The charm reveals a way to free Oben, but he regrets what it requires. He asks you to find his soulless body deep in the den and kill it. Then you must use the charm on the fallen body to release his spirit. He sees no other way to escape the Gnarlpine's control."}
function P:FixtureSnapshot()
    local f=self.fixture
    local goals={}
    for i,name in ipairs({"Raven Claw Talisman","Black Feather Quill","Sapphire of Sky","Rune of Nesting","Shaman Voodoo Charm"}) do
        if i<5 or not f.storyEarned then
            local done=f.done[i]
            goals[#goals+1]={index=i,action="get",text=name..(done and " - 1/1" or " - 0/1"),
                status=done and "complete" or "incomplete",progress=done and 1 or 0,
                hint=i==5 and "Defeat Gnarlpine Shamans in the next room." or nil}
        end
    end
    if f.storyEarned then
        goals[#goals+1]={index=6,action="goal",text="Release Oben's spirit",status="incomplete",
            hint="Defeat his body, then use the provided charm."}
    end
    return self.Copy({version=1,source="fixture",available=true,
        guide={id="banethil-presentation-fixture",title="Ban'ethil Barrow Den"},
        step={index=f.step,total=2,title="Relics of Wakening / Oben's request"},goals=goals,
        navigation={title="Explore the chambers. Cave floors are not tracked."},paused=false,
        context=f.storyEarned and revelation or request,
        -- Retained PoC field for consumers; explicit fixture event only.
        story=f.storyEarned and revelation.body or nil})
end
function P:FixtureCommand(command)
    if command=="reset" then self.fixture={step=1,done={}};self.fixtureCombat=nil end
    local f=self.fixture
    if not f then return end
    local index=tonumber(command:match("^goal ([1-5])$"))
    if index and not (index==5 and f.storyEarned) then f.done[index]=not f.done[index] end
    if command=="story" then
        if not f.done[5] then ZGV:Print("Simulation: collect the charm with /zgpoc goal 5 first.");return end
        -- Explicit simulated quest exchange, not an inference from step/count.
        f.storyEarned=true;f.step=2
    end
    if command=="next" then f.step=math.min(2,f.step+1) end
    if command=="prev" then f.step=math.max(1,f.step-1) end
    if command=="combat" then self.fixtureCombat=true;self:FoldStory(true) end
    if command=="peace" then self.fixtureCombat=nil end
    self:Publish()
end
