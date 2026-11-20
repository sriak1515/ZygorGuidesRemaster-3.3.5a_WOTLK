-- Campaign route geometry and pooled map painters. Native navigation owns progression.
local ZGV = ZygorGuidesViewer
local W = ZGV.CampaignWayfinder
local R = { mini={}, world={}, path={} }
ZGV.CampaignRoute = R
local A = DongleStub and (({pcall(DongleStub,'Astrolabe-0.4-Zygor')})[2] or ({pcall(DongleStub,'Astrolabe-0.4')})[2])
local sqrt, floor = math.sqrt, math.floor
local look = {
 miniSize=4, miniSpacing=9, miniGap=12,
 worldZoneSize=4, worldLargeSize=3, worldSpacing=8, worldGap=10,
 rimRadius=1, fill={0.78,0.58,0.26}, rim={0.20,0.12,0.06},
 texture='Interface\\AddOns\\ZygorGuidesViewerRM\\Textures\\CampaignRouteDot',
}

-- UI units to physical pixels, including the frame's inherited scale.
function R.PixelScale(frame)
 local resolutions={GetScreenResolutions()}
 local height=tonumber((resolutions[GetCurrentResolution()] or ''):match('%u?%d+%s*[xX]%s*(%d+)')) or 768
 return frame:GetEffectiveScale()*height/768
end

-- Each point has map x/y and screen x/y. Spacing carries across bends.
function R.Strokes(points, count, spacing, radius, goalGap, emit)
 if count<2 then return end
 local remaining=spacing
 local gx,gy=points[count].sx,points[count].sy
 for i=1,count-1 do
  local a,b=points[i],points[i+1]
  local dx,dy=b.sx-a.sx,b.sy-a.sy
  local length=sqrt(dx*dx+dy*dy)
  while length>0 and remaining<=length do
   local t=remaining/length
   local sx,sy=a.sx+dx*t,a.sy+dy*t
   if (not radius or sx*sx+sy*sy<radius*radius) and (sx-gx)^2+(sy-gy)^2>=goalGap*goalGap then
    emit(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,i)
   end
   remaining=remaining+spacing
  end
  remaining=remaining-length
 end
end

-- The compiler's route destination is the first coordinate-bearing native goal.
function R.Target(step)
 if not step or not step.goals then return end
 for _,goal in ipairs(step.goals) do
  if goal.x and goal.y then return goal.map or step.map,goal.x,goal.y end
 end
end

local function point(path,i,x,y,sx,sy)
 local p=path[i]
 if not p then p={}; path[i]=p end
 p.x,p.y,p.sx,p.sy=x,y,sx,sy
end

local function frame(pool,i,parent,size,scale)
 local f=pool[i]
 if not f then
  f=CreateFrame('Frame',nil,parent)
  f:SetFrameStrata('HIGH'); f:SetFrameLevel(parent:GetFrameLevel()+5)
  f.rim=f:CreateTexture(nil,'ARTWORK'); f.rim:SetAllPoints()
  f.rim:SetTexture(look.texture); f.rim:SetVertexColor(unpack(look.rim))
  f.icon=f:CreateTexture(nil,'OVERLAY'); f.icon:SetPoint('CENTER')
  f.icon:SetTexture(look.texture); f.icon:SetVertexColor(unpack(look.fill))
  f:Hide(); pool[i]=f
 end
 f:SetSize((size+2*look.rimRadius)/scale,(size+2*look.rimRadius)/scale)
 f.icon:SetSize(size/scale,size/scale)
 return f
end

function R:Hide(pool,from,mini)
 for i=from,#pool do
  local f=pool[i]
  if f:IsShown() then
   if mini then A:RemoveIconFromMinimap(f) end
   f:Hide()
  end
 end
end

-- Reused callbacks avoid creating a new closure on every redraw.
local function miniDot(x,y,segment)
 local r=R; r.used=r.used+1
 local f=frame(r.mini,r.used,Minimap,look.miniSize,r.miniScale)
 f:SetAlpha(segment==1 and 0.85 or 0.34)
 A:PlaceIconOnMinimap(f,r.c,r.z,x,y)
end
local function worldDot(x,y,segment)
 local r=R; r.used=r.used+1
 local f=frame(r.world,r.used,r.overlay,r.worldSize,r.worldScale)
 f:SetAlpha(segment==1 and 0.85 or 0.34)
 local wx,wy=A:PlaceIconOnWorldMap(r.overlay,f,r.c,r.z,x,y)
 if wx and wy and wx>=0 and wx<=1 and wy>=0 and wy<=1 then f:Show() else f:Hide() end
end

function R:Update()
 if not A or not ZGV.Pointer or not ZGV.Pointer.ready or not ZGV.db then return end
 local data=W:Get(ZGV.CurrentGuide,ZGV.CurrentStep)
 local map,tx,ty=self.Target(ZGV.CurrentStep)
 local c,z,x,y=A:GetCurrentPlayerPosition()
 local mc,mz
 if map then mc,mz=ZGV:GetMapZoneNumbers(map) end
 if not ZGV.db.profile.campaignrouteline or not data or #data.waypoints==0 or not x or not y or not c or not z or mc~=c or mz~=z then
  self:Hide(self.mini,1,true); self:Hide(self.world,1,false); return
 end
 self.c,self.z=c,z
 local count=1
 point(self.path,1,x,y,0,0)
 for i=(W.step==ZGV.CurrentStep and W.index or 1),#data.waypoints do
  local p=data.waypoints[i]
  local pc,pz=ZGV:GetMapZoneNumbers(p.map)
  if pc~=c or pz~=z then self:Hide(self.mini,1,true); self:Hide(self.world,1,false); return end
  count=count+1; point(self.path,count,p.x/100,p.y/100,0,0)
 end
 count=count+1; point(self.path,count,tx/100,ty/100,0,0)
 local zoom=Minimap:GetZoom()
 local sizes=MinimapSize and (A.minimapOutside and MinimapSize.outdoor or MinimapSize.indoor)
 local diameter=sizes and sizes[zoom]
 if diameter and Minimap:GetWidth()>0 then
  local scale=Minimap:GetWidth()/diameter
  for i=2,count do
   local p=self.path[i]
   local dist,dx,dy=A:ComputeDistance(c,z,x,y,c,z,p.x,p.y)
   if not dist then self:Hide(self.mini,1,true); self:Hide(self.world,1,false); return end
   p.sx,p.sy=dx*scale,dy*scale
  end
  self.miniScale=self.PixelScale(Minimap)
  self.used=0; self.Strokes(self.path,count,look.miniSpacing/self.miniScale,Minimap:GetWidth()/2-(look.miniSize/2+look.rimRadius)/self.miniScale,look.miniGap/self.miniScale,miniDot)
  self:Hide(self.mini,self.used+1,true)
 else self:Hide(self.mini,1,true) end
 local overlay=ZGV.Pointer.OverlayFrame
 local wc,wz=GetCurrentMapContinentAndZone()
 if overlay and overlay:IsShown() and wc==c and wz==z then
  self.overlay=overlay
  self.worldScale=self.PixelScale(overlay)
  self.worldSize=(wz==0) and look.worldLargeSize or look.worldZoneSize
  for i=1,count do local p=self.path[i]; p.sx,p.sy=p.x*overlay:GetWidth(),p.y*overlay:GetHeight() end
  self.used=0; self.Strokes(self.path,count,look.worldSpacing/self.worldScale,nil,look.worldGap/self.worldScale,worldDot)
  self:Hide(self.world,self.used+1,false)
 else self:Hide(self.world,1,false) end
end

function R:OnFocus(step)
 self.observedStep=step
 self.incomplete=step and step.IsComplete and not step:IsComplete()
end

function R:OnCompletion(guide,step,complete)
 if self.observedStep~=step then self.observedStep=step; self.incomplete=not complete end
 if not complete then self.incomplete=true; return end
 if not self.incomplete then return end
 self.incomplete=false
 local _,id=W:Get(guide,step)
 local map,tx,ty=self.Target(step)
 if not id or not map or not A or not ZGV.db then return end
 local c,z,x,y=A:GetCurrentPlayerPosition()
 local tc,tz=ZGV:GetMapZoneNumbers(map)
 if not c or not z or not x or not y or not tc or not tz then return end
 local distance=A:ComputeDistance(c,z,x,y,tc,tz,tx/100,ty/100)
 local arrow=ZGV.Pointer and ZGV.Pointer.ArrowFrame and ZGV.Pointer.ArrowFrame.waypoint
 local direct=arrow and arrow.c==tc and arrow.z==tz and type(arrow.x)=='number' and type(arrow.y)=='number' and math.abs(arrow.x-tx/100)<0.00001 and math.abs(arrow.y-ty/100)<0.00001
 local log=ZGV.db.profile.campaignroutelog or {}; ZGV.db.profile.campaignroutelog=log
 log[#log+1]=('%s player %.2f,%.2f target %.2f,%.2f yards %s direct %s'):format(id,x*100,y*100,tx,ty,distance and ('%.1f'):format(distance) or '?',direct and 'yes' or 'no')
 if #log>50 then table.remove(log,1) end
end

SLASH_ZGVCAMPAIGNROUTE1='/zgvroutelog'
SlashCmdList.ZGVCAMPAIGNROUTE=function()
 local log=ZGV.db and ZGV.db.profile.campaignroutelog or {}
 for i=math.max(1,#log-9),#log do ZGV:Print(log[i]) end
end
if type(ZGV.startups)=='table' then
 table.insert(ZGV.startups,function()
  local f=CreateFrame('Frame'); local elapsed=0
  f:SetScript('OnUpdate',function(_,dt)
   elapsed=elapsed+dt
   if elapsed>=0.1 then elapsed=0; R:Update() end
  end)
 end)
end
