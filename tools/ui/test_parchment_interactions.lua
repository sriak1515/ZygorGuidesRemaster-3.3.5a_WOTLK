-- Exercise the actual native click dispatcher used by the prototype, without a client.
local root=arg[1] or "ZygorGuidesViewerRM"
local file=assert(io.open(root.."/ZygorGuidesViewer.lua","rb"))
local src=file:read("*a");file:close()
local start=assert(src:find("function me:GoalOnClick(goalframe,button)",1,true))
local finish=assert(src:find("function me:GoalOnEnter(goalframe)",start,true))
local z={db={profile={showallsteps=false}},recentlyCompletedGoals={},recentlyStickiedGoals={},recentlyVisitedCoords={},questsbyid={},completedQuests={}}
function z:Debug() end
function z:Print(value) self.printed=value end
function z:ParchmentEnabled() return true end
function z:SetWaypoint(value) self.waypoint=value end
function z:UpdateFrame() self.refreshed=true end
function z:TryToCompleteStep() self.tried=true end
function z:FocusStep(n) self.focused=n end
IsShiftKeyDown=function() return false end
local chunk=assert(loadstring(src:sub(start,finish-1)))
setfenv(chunk,setmetatable({me=z},{__index=_G}));chunk()
local step={}
z.CurrentStep=step
local function click(goal,button)
    local row={goal=goal,GetParent=function() return {step=step} end}
    z:GoalOnClick({GetParent=function() return row end},button)
end
local waypoint={num=7,x=12,y=34}
click(waypoint,"LeftButton");assert(z.waypoint==7)
click(waypoint,"RightButton")
assert(z.recentlyStickiedGoals[waypoint] and z.refreshed,"manual completion stopped working")
z.recentlyCompletedGoals[waypoint]=true
click(waypoint,"RightButton")
assert(not z.recentlyStickiedGoals[waypoint],"manual uncompletion stopped working")
z.printed=nil
click({questid=783,quest="A Threat Within"},"LeftButton")
assert(not z.printed,"quest click printed legacy debug IDs")
local confirm={action="confirm",num=1}
step.goals={confirm}
click(confirm,"LeftButton")
assert(z.recentlyStickiedGoals[confirm] and z.tried,"confirm no longer triggers progression")
local branching={GetJumpDestination=function() return 3,"test-guide" end}
local choice={action="confirm",next="chapter-two",parentStep=branching,IsVisible=function() return true end,IsCompleteable=function() return true end,IsComplete=function() return true end}
z.CurrentGuideName="test-guide";z.CurrentGuide={steps={{},{},{}}}
click(choice,"LeftButton")
assert(z.focused==3,"confirm/next branch bypassed")
print("PASS: actual native dispatcher retains waypoint clicks, manual completion, confirm progression and branching; prototype omits quest-ID diagnostics")
