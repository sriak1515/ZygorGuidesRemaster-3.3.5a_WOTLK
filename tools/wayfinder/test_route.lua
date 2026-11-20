local astro={GetCurrentPlayerPosition=function() return 1,1,.5,.5 end,
 ComputeDistance=function(_,_,_,x,y,_,_,a,b) local dx,dy=(a-x)*1000,(b-y)*1000; return math.sqrt(dx*dx+dy*dy),dx,dy end}
DongleStub=function() return astro end
SlashCmdList={}
ZygorGuidesViewer={startups={},RegisterCampaignGuideMetadata=function() return true end,
 db={profile={campaignrouteline=true}},GetMapZoneNumbers=function() return 1,1 end}
dofile('ZygorGuidesViewerRM/Wayfinder.lua')
dofile('ZygorGuidesViewerRM/CampaignRoute.lua')
local W,R=ZygorGuidesViewer.CampaignWayfinder,ZygorGuidesViewer.CampaignRoute
GetScreenResolutions=function() return '1920x1080' end
GetCurrentResolution=function() return 1 end
local scaleFrame={GetEffectiveScale=function() return 0.8 end}
assert(math.abs(R.PixelScale(scaleFrame)-1.125)<0.00001)
local hits={}
local function capture(x,y,segment) hits[#hits+1]={x=x,y=y,segment=segment} end
local route={{x=0,y=0,sx=0,sy=0},{x=10,y=0,sx=10,sy=0},{x=10,y=10,sx=10,sy=10}}
R.Strokes(route,3,6,nil,0,capture)
assert(#hits==3 and hits[1].x==6 and hits[2].y==2 and hits[3].y==8)
assert(hits[1].segment==1 and hits[2].segment==2)
hits={}; R.Strokes(route,3,6,10,0,capture); assert(#hits==1 and hits[1].x==6)
hits={}; R.Strokes(route,3,6,nil,3,capture); assert(#hits==2)
hits={}; R.Strokes(route,1,6,nil,0,capture); assert(#hits==0)
local function p(x,y) return {x=x,y=y} end
local i=W.Select({p(5,0),p(40,0),p(80,0)},1); assert(i==2)
assert(ZygorGuidesViewer:RegisterCampaignWayfinding({guide_id='g',steps={a={waypoints={}}}}))
assert(ZygorGuidesViewer:RegisterCampaignGuideMetadata({guide={id='g'},native_views={{registration='g',steps={{source_step_id='a',native_parts={'a'}}}}}}))
local guide,step={title='g'},{label='a',map='m',goals={{x=60,y=50}}}
ZygorGuidesViewer.CurrentGuide,ZygorGuidesViewer.CurrentStep=guide,step
ZygorGuidesViewer.Pointer={ready=true,ArrowFrame={waypoint={c=1,z=1,x=.6,y=.5}}}
R:Update(); assert(#R.mini==0 and #R.world==0)
for n=1,55 do R:OnCompletion(guide,step,false); R:OnCompletion(guide,step,true) end
local log=ZygorGuidesViewer.db.profile.campaignroutelog
assert(#log==50 and log[1]:find('yards 100.0 direct yes',1,true))
local printed=0; ZygorGuidesViewer.Print=function() printed=printed+1 end
SlashCmdList.ZGVCAMPAIGNROUTE(); assert(printed==10)
print('campaign route geometry and completion tests passed')
local created=0
local function newFrame()
 created=created+1
 local f={shown=false,level=1}
 function f:SetSize() end
 function f:SetAlpha() end
 function f:GetEffectiveScale() return 768/1080 end
 function f:SetFrameStrata() end
 function f:SetFrameLevel() end
 function f:GetFrameLevel() return self.level end
 function f:IsShown() return self.shown end
 function f:Show() self.shown=true end
 function f:Hide() self.shown=false end
 function f:CreateTexture() return {SetAllPoints=function() end,SetPoint=function() end,SetSize=function() end,SetTexture=function() end,SetVertexColor=function() end,SetAlpha=function() end} end
 return f
end
CreateFrame=function() return newFrame() end
Minimap=newFrame(); function Minimap:GetZoom() return 0 end; function Minimap:GetWidth() return 100 end
MinimapSize={indoor={[0]=200},outdoor={[0]=200}}
GetCurrentMapContinentAndZone=function() return 1,1 end
local overlay=newFrame(); overlay:Show(); function overlay:GetWidth() return 1000 end; function overlay:GetHeight() return 1000 end
ZygorGuidesViewer.Pointer.OverlayFrame=overlay
function astro:PlaceIconOnMinimap(f,_,_,x,y) assert(((x-.5)*1000)^2+((y-.5)*1000)^2 < 92^2); f:Show() end
function astro:RemoveIconFromMinimap(f) f:Hide() end
function astro:PlaceIconOnWorldMap(_,_,_,_,x,y) return x,y end
W.guides.g.a.waypoints={{map='m',x=55,y=50}}
W.step,W.index=step,1
R:Update(); assert(#R.mini>0 and #R.world>0)
local before=created; R:Update(); assert(created==before)
-- At a different inherited scale, the spacing remains eight physical pixels.
local positions={}
function astro:PlaceIconOnWorldMap(_,_,_,_,x,y) positions[#positions+1]=x; return x,y end
function overlay:GetEffectiveScale() return 0.5*768/1080 end
R:Update()
assert(#positions>1 and math.abs((positions[2]-positions[1])*overlay:GetWidth()*R.worldScale-8)<0.00001)
-- A passed waypoint is omitted from the path.
W.guides.g.a.waypoints={{map='m',x=45,y=50},{map='m',x=55,y=50}}
W.index=2; R:Update(); assert(R.path[2].x==.55)
ZygorGuidesViewer.db.profile.campaignrouteline=false; R:Update()
assert(not R.mini[1]:IsShown() and not R.world[1]:IsShown())
print('campaign route pooling and visibility tests passed')
local made=0
ZygorGuidesViewer.Pointer.waypoints={}
function ZygorGuidesViewer.Pointer:SetWaypoint() made=made+1; local marker={}; self.waypoints[marker]=true; return marker end
function ZygorGuidesViewer.Pointer:RemoveWaypoint(marker) self.waypoints[marker]=nil end
ZygorGuidesViewer.SetWaypoint=function() end
ZygorGuidesViewer.CurrentStep.GetTitle=function() return 'test' end
UnitIsDeadOrGhost=function() return false end
W.index,W.target,W.marker=1,nil,nil
W:Update(); assert(made==0)
ZygorGuidesViewer.db.profile.campaignwaypointarrow=true
W:Update(); assert(made==1 and W.marker)
ZygorGuidesViewer.db.profile.campaignwaypointarrow=false
W:Update(); assert(not W.marker)
print('campaign arrow setting tests passed')
