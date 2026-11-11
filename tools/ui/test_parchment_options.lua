-- Execute both normal settings presentations against their real callbacks.
local root=arg[1] or "ZygorGuidesViewerRM"
local source=assert(io.open(root.."/Options.lua","rb")):read("*a")
local me={db={profile={fontsize=13,fontsecsize=11}},alignments=0,updates=0}
function me:AlignFrame() self.alignments=self.alignments+1 end
function me:UpdateFrame() self.updates=self.updates+1 end
me.Parchment={settings={contextsize=14}}
function me.Parchment:Settings() return self.settings end
function me.Parchment:SetContextSize(value) self.settings.contextsize=value end
local env=setmetatable({self=me,L=setmetatable({},{__index=function(_,k) return k end}),
    Setter_Simple=function(info,value) me.db.profile[info[#info]]=value end},{__index=_G})
for key,expected in pairs({fontsize=24,fontsecsize=22,parchmentreadingsize=24}) do
    local count=0
    for block in source:gmatch("\n[\t ]*"..key.." = (%b{})") do
        count=count+1
        local chunk=assert(loadstring("return "..block));setfenv(chunk,env)
        local option=chunk()
        assert(option.max==expected and option.step==1)
        if key=="parchmentreadingsize" then
            option.set({},19);assert(option.get()==19)
        else
            option.set({key},17);assert(me.db.profile[key]==17)
        end
    end
    assert(count==2,"both settings presentations must expose "..key)
end
assert(me.alignments==4 and me.updates==4)
print("PASS: both normal font settings presentations execute authoritative native setters and the dedicated reading-size control")

me.Presentation={Start=function(self,mode) self.mode=mode end,Stop=function(self) self.mode=nil end}
local count=0
for block in source:gmatch("\n[\t ]*adventureinterface = (%b{})") do
    count=count+1
    local chunk=assert(loadstring("return "..block));setfenv(chunk,env)
    local option=chunk()
    assert(not option.get());option.set({},true);assert(option.get() and me.Presentation.mode=="live")
    option.set({},false);assert(not option.get())
end
assert(count==2,"both existing settings presentations must expose adventure activation")
print("PASS: adventure interface is available through both normal settings presentations")
