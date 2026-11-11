-- Presentation data ONLY. Never select/register a guide or send quest events.
local P=ZygorGuidesViewer.Presentation
function P:FixtureSnapshot()
    local f=self.fixture
    local goals={}
    for i,name in ipairs({"Raven Claw Talisman","Black Feather Quill","Sapphire of Sky","Rune of Nesting","Shaman Voodoo Charm"}) do
        local done=f.done[i]
        goals[i]={index=i,action="get",text=name,status=done and "complete" or "incomplete",progress=done and 1 or 0}
    end
    return {version=1,source="fixture",available=true,
        guide={id="banethil-presentation-fixture",title="Ban'ethil (SIMULATED)"},
        step={index=f.step,total=2,title="Concurrent cave objectives"},goals=goals,
        navigation={title="Cave floors are not tracked"},paused=false,
        story=f.step==2 and "SIMULATED earned context: Oben's request has been delivered." or nil}
end
function P:FixtureCommand(command)
    if command=="reset" then self.fixture={step=1,done={}} end
    local f=self.fixture
    if not f then return end
    local index=tonumber(command:match("^goal ([1-5])$"))
    if index then f.done[index]=not f.done[index] end
    if command=="story" then f.step=2 end
    if command=="next" then f.step=math.min(2,f.step+1) end
    if command=="prev" then f.step=math.max(1,f.step-1) end
    self:Publish()
end
