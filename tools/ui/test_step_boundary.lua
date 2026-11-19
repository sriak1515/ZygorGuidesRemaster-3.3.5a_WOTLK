-- Exercise the real step-navigation function without loading the client.
local file = assert(io.open('ZygorGuidesViewerRM/ZygorGuidesViewer.lua', 'rb'))
local source = file:read('*a'); file:close()
local start = assert(source:find('function me:SkipStep(', 1, true))
local finish = assert(source:find('function me:Print(', start, true))
local viewer = {}
assert(loadstring('local me=...\n' .. source:sub(start, finish - 1)))(viewer)
local first = {AreRequirementsMet=function() return true end}
local last = {AreRequirementsMet=function() return true end}
viewer.CurrentGuide = {steps={first, last}, next='NEXT-GUIDE'}
viewer.CurrentGuideName = 'FIX-01'
viewer.CurrentStepNum = 1
viewer.CurrentStep = first
viewer.completioninterval, viewer.completionintervallong = 0, 1
viewer.InlineButtonsEnabled = function() return false end
viewer.Debug = function() end
viewer.FocusStepQuiet = function(self, i) self.CurrentStepNum=i; self.CurrentStep=self.CurrentGuide.steps[i] end
viewer.FocusStep = function(self, i) self.focused=i end
viewer.SetGuide = function(self) self.changedGuide=true end
viewer:SkipStep(1, false)
assert(viewer.CurrentStepNum == 2 and viewer.focused == 2, 'ordinary next did not advance')
viewer:SkipStep(1, true)
assert(viewer.CurrentStepNum == 2 and #viewer.CurrentGuide.steps == 2, 'last step changed')
assert(not viewer.changedGuide, 'automatically changed guide')
viewer.CurrentGuide.next = nil
viewer:SkipStep(1, false)
assert(viewer.CurrentStepNum == 2 and #viewer.CurrentGuide.steps == 2, 'added a completion step')
viewer.CurrentStepNum, viewer.CurrentStep = 1, first
viewer.CurrentGuide.next = 'NEXT-GUIDE'
last.AreRequirementsMet = function() return false end
viewer:SkipStep(1, false)
assert(viewer.CurrentStepNum == 2 and not viewer.changedGuide, 'skipped past the last step')
print('PASS: final step remains selected, including a linked next guide')
