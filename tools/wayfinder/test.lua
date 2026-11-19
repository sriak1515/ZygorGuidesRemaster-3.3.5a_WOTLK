local astro={GetCurrentPlayerPosition=function() return 1,1,0.5,0.5 end}
DongleStub=function() return astro end
ZygorGuidesViewer={startups={},RegisterCampaignGuideMetadata=function() return true end}
dofile('ZygorGuidesViewerRM/Wayfinder.lua')
local W=ZygorGuidesViewer.CampaignWayfinder
local function point(x,y) return {x=x,y=y} end
local function check(route,index,expectedIndex,expectedTarget)
 local i,t=W.Select(route,index)
 assert(i==expectedIndex and t==expectedTarget, ('got %s/%s'):format(i,tostring(t)))
end
check({point(5,0),point(50,0),point(100,0)},1,2,2)
check({point(40,0),point(10,0),point(80,0)},1,3,3)
check({point(5,0),point(40,0),point(80,0)},2,2,2)
check({point(30,0),point(60,0),point(90,0),point(1,0)},1,1,1)
check({point(5,0)},1,2,nil)
check({point(200,0),point(250,0)},1,1,nil)
check({point(-200,10),point(200,10)},1,1,1)
assert(not ZygorGuidesViewer:RegisterCampaignWayfinding({guide_id='g',steps={a={waypoints={{map='m',x=101,y=1}}}}}))
assert(ZygorGuidesViewer:RegisterCampaignWayfinding({guide_id='g',steps={a={hint='h',waypoints={{map='m',x=10,y=20}}}}}))
assert(ZygorGuidesViewer:RegisterCampaignGuideMetadata({guide={id='g'},native_views={{registration='guide',steps={{source_step_id='a',native_parts={'label'}}}}}}))
assert(W:Get({title='guide'},{label='label'}).hint=='h')
ZygorGuidesViewer.CurrentGuide={title='guide'}
ZygorGuidesViewer.CurrentStep={label='label'}
ZygorGuidesViewer.GetMapZoneNumbers=function() return 1,2 end
ZygorGuidesViewer.Pointer={waypoints={}}
W:Update()
assert(W.index==1 and W.marker==nil)
print('wayfinder pure and registration tests passed')
