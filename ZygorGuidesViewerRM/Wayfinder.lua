-- Optional campaign navigation. Native goals remain responsible for progression.
local ZGV = ZygorGuidesViewer
local W = { guides={}, labels={} }
ZGV.CampaignWayfinder = W
local A = DongleStub and (({pcall(DongleStub,'Astrolabe-0.4-Zygor')})[2] or ({pcall(DongleStub,'Astrolabe-0.4')})[2])

function ZGV:RegisterCampaignWayfinding(data)
 if type(data)~='table' or type(data.guide_id)~='string' or type(data.steps)~='table' then return false end
 for id,step in pairs(data.steps) do
  if type(id)~='string' or type(step)~='table' or (step.hint~=nil and type(step.hint)~='string') or type(step.waypoints)~='table' then return false end
  for _,p in ipairs(step.waypoints) do
   if type(p.map)~='string' or type(p.x)~='number' or type(p.y)~='number' or p.x<0 or p.x>100 or p.y<0 or p.y>100 then return false end
  end
 end
 W.guides[data.guide_id]=data.steps
 return true
end

-- Narration supplies the existing native-label to source-step mapping.
local register = ZGV.RegisterCampaignGuideMetadata
function ZGV:RegisterCampaignGuideMetadata(metadata)
 local ok=register(self,metadata)
 if ok then
  local view=metadata.native_views[1]
  local labels={}
  for _,step in ipairs(view.steps) do
   for _,part in ipairs(step.native_parts) do labels[part]=step.source_step_id end
  end
  W.labels[view.registration]={id=metadata.guide.id,steps=labels}
 end
 return ok
end
function W:Get(guide,step)
 local mapping=guide and self.labels[guide.title]
 local id=mapping and step and mapping.steps[step.label]
 return id and self.guides[mapping.id] and self.guides[mapping.id][id], id
end

-- Coordinates passed to this pure function are yard offsets from the player.
function W.Select(points,index)
 local nearest=math.huge
 for i,p in ipairs(points) do
  nearest=math.min(nearest,math.sqrt(p.x*p.x+p.y*p.y))
  local q=points[i+1]
  if q then
   local dx,dy=q.x-p.x,q.y-p.y
   local n=dx*dx+dy*dy
   local t=n>0 and math.max(0,math.min(1,-(p.x*dx+p.y*dy)/n)) or 0
   nearest=math.min(nearest,math.sqrt((p.x+t*dx)^2+(p.y+t*dy)^2))
  end
 end
 if nearest>150 then return index,nil end
 local current=points[index]
 if not current then return index,nil end
 local d=math.sqrt(current.x^2+current.y^2)
 local advance=index-1
 for i=index,math.min(index+2,#points) do
  local p=points[i]; local nd=math.sqrt(p.x^2+p.y^2)
  if nd<=15 or (i>index and nd<d) then advance=i end
 end
 index=math.max(index,advance+1)
 return index,points[index] and index or nil
end

function W:Update()
 local step=ZGV.CurrentStep
 local data,id=self:Get(ZGV.CurrentGuide,step)
 if step~=self.step or id~=self.id then
  if self.marker and ZGV.Pointer.waypoints[self.marker] then ZGV.Pointer:RemoveWaypoint(self.marker) end
  self.marker=nil
  self.step,self.id,self.index,self.target=step,id,1,nil
 end
 if not data or #data.waypoints==0 or not A or not ZGV.Pointer then return end
 local c,z,x,y=A:GetCurrentPlayerPosition()
 if not c or not z or not x or not y then return end
 local points={}
 for i,p in ipairs(data.waypoints) do
  local mc,mz=ZGV:GetMapZoneNumbers(p.map)
  if mc~=c or mz~=z then
   if self.marker then ZGV.Pointer:RemoveWaypoint(self.marker); self.marker=nil; self.target=nil; ZGV:SetWaypoint() end
   return
  end
  local dist,dx,dy=A:ComputeDistance(c,z,x,y,mc,mz,p.x/100,p.y/100)
  if not dist or not dx or not dy then return end
  points[i]={x=dx,y=dy}
 end
 local index,target=self.Select(points,self.index)
 self.index=index
 if target~=self.target or (target and (not self.marker or not ZGV.Pointer.waypoints[self.marker])) then
  if self.marker and ZGV.Pointer.waypoints[self.marker] then ZGV.Pointer:RemoveWaypoint(self.marker) end
  self.marker=nil; self.target=target
  if target then
   local p=data.waypoints[target]
   self.marker=ZGV.Pointer:SetWaypoint(nil,p.map,p.x,p.y,{title=step:GetTitle(),type='wayfinder',onminimap='always',overworld=true})
  else ZGV:SetWaypoint() end
 elseif target and self.marker and not UnitIsDeadOrGhost('player') and ZGV.Pointer.ArrowFrame.waypoint~=self.marker then
  ZGV.Pointer:ShowArrow(self.marker)
 end
end
if type(ZGV.startups)=='table' then
 table.insert(ZGV.startups,function()
  local f=CreateFrame('Frame'); local elapsed=0
  f:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt; if elapsed>=0.5 then elapsed=0; W:Update() end end)
 end)
end
