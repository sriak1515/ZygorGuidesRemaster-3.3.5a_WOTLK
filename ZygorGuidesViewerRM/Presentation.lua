-- Experimental, versioned projection. No quest cache or progression ownership.
local ZGV=ZygorGuidesViewer
if not ZGV then return end
local P={listeners={}}
ZGV.Presentation=P

local function copy(value)
    if type(value)~="table" then return value end
    local result={}
    for k,v in pairs(value) do result[k]=copy(v) end
    return result
end
P.Copy=copy

function ZGV:GetPresentationSnapshot()
    local guide,step=self.CurrentGuide,self.CurrentStep
    local snapshot={version=1,source="live",available=guide~=nil and step~=nil,
        guide={id=self.CurrentGuideName,title=guide and (guide.title_short or guide.title)},
        step={index=self.CurrentStepNum,total=guide and guide.steps and #guide.steps or 0,
            label=step and step.label,title=step and step.title},goals={},
        navigation={},paused=self.pause and true or false}
    for i,goal in ipairs(step and step.goals or {}) do
        local status,progress=goal:GetStatus()
        if status~="hidden" then
            snapshot.goals[#snapshot.goals+1]={index=i,action=goal.action,questId=goal.questid,
                objective=goal.objnum,text=goal:GetText(),status=status,progress=progress,
                routeGroup=goal.routegroup and true or false,
                map=goal.map,x=goal.x,y=goal.y}
        end
    end
    -- Arrow target can differ from an authored goto (travel routing, etc.).
    local waypoint=self.Pointer and self.Pointer.ArrowFrame and self.Pointer.ArrowFrame.waypoint
    if waypoint then
        for _,key in ipairs({"c","z","x","y","type","title","t"}) do
            local v=waypoint[key]
            if type(v)=="number" or type(v)=="string" then snapshot.navigation[key]=v end
        end
    end
    return copy(snapshot)
end

function P:Snapshot()
    if self.fixture then return self:FixtureSnapshot() end
    return ZGV:GetPresentationSnapshot()
end

-- Deterministic scalar signature, including text-only and navigation changes.
local function signature(value)
    if type(value)~="table" then return type(value)..":"..tostring(value) end
    local keys={}
    for k in pairs(value) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local parts={}
    for _,k in ipairs(keys) do parts[#parts+1]=signature(k).."="..signature(value[k]) end
    return "{"..table.concat(parts,";").."}"
end

function ZGV:SubscribePresentation(callback)
    assert(type(callback)=="function","presentation callback required")
    P.listeners[callback]=true
    local active=true
    return function() if active then P.listeners[callback]=nil;active=false end end
end

function P:Publish()
    if not next(self.listeners) or self.publishing then return end
    self.publishing=true
    local ok,snapshot=pcall(self.Snapshot,self)
    if not ok then
        -- Restore legacy presentation on an adapter failure; session only.
        if self.mode then self:Stop() end
        self.listeners={}
        self.publishing=nil
        ZGV:Print("Presentation snapshot failed; use /zgpoc off or reload. "..tostring(snapshot))
        return
    end
    local sig=signature(snapshot)
    if sig~=self.signature then
        local identity=signature({snapshot.source,snapshot.guide.id,snapshot.step.index})
        local reason=identity~=self.identity and "step" or "progress"
        self.signature,self.identity=sig,identity
        local callbacks={}
        for callback in pairs(self.listeners) do callbacks[#callbacks+1]=callback end
        for _,callback in ipairs(callbacks) do
            local success,err=pcall(callback,copy(snapshot),reason)
            if not success then
                self.listeners[callback]=nil
                if self.mode then self:Stop() end
                ZGV:Print("Presentation listener disabled: "..tostring(err))
            end
        end
    end
    self.publishing=nil
end

-- Opt-in subscriptions only. Poll also catches pointer/text changes and early
-- returns in native completion. No calls to TryToCompleteStep or quest events.
local notifier=CreateFrame("Frame")
notifier:SetScript("OnUpdate",function(_,elapsed)
    if not next(P.listeners) then return end
    P.elapsed=(P.elapsed or 0)+elapsed
    if P.elapsed<0.2 then return end
    P.elapsed=0
    P:Publish()
end)
