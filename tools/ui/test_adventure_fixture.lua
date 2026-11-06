-- Product fixture uses the real parser and completion model, no live quest state.
local root=arg[1] or "ZygorGuidesViewerRM"
-- Reuse the existing model setup, which also verifies the untouched 11 indices.
assert(loadfile("tools/ui/test_parchment_fixtures.lua"))()
local ZGV=ZygorGuidesViewer
local before=#ZGV.registeredguides
assert(loadfile(root.."/Guides/Tests/AdventureFixture.lua"))()
assert(#ZGV.registeredguides==before+1)
local entry=ZGV.registeredguides[#ZGV.registeredguides]
local guide=assert(ZGV:ParseEntry(entry.raw));guide.title=entry.title
assert(#guide.steps==5 and not guide.defaultfor and not guide.next)
ZGV.CurrentGuide=guide
for i,step in ipairs(guide.steps) do
    ZGV.CurrentStep,ZGV.CurrentStepNum=step,i
    local complete,possible=step:IsComplete()
    assert(not complete and possible,"fixture advanced before simulated event")
    for _,g in ipairs(step.goals) do
        assert(not g.questid and not g.x and not g.useitemid,"fixture depends on live quest/navigation/inventory")
    end
    if i<5 then
        local g=step.goals[2]
        assert(g.script and g:GetStatus()=="incomplete")
        ZGV:AdventureFixtureComplete(i)
        assert(g:GetStatus()=="complete" and step:IsComplete(),"native step did not complete after event")
    end
    assert((ZGV:AdventureFixtureBackground(step)~=nil)==(i==4),"background appeared on an unrelated scene")
end
local refreshes=ZGV.refreshes
ZGV.CurrentStepNum=5
ZGV:AdventureFixtureComplete(1)
assert(ZGV.refreshes==refreshes,"stale fixture action changed the current scene")
ZGV.AdventureFixtureFlags={}
assert(not guide.steps[3]:IsComplete(),"reset retained rescue completion")
print("PASS: five adventure excerpts parse, gate native completion on isolated events, and attach background only to its authored scene")
