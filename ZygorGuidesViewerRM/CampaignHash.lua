-- SHA-256 of exact compiled guide bytes. No client/API or saved-state dependency.
local ZGV = ZygorGuidesViewer
if not ZGV then return end
local floor, mod = math.floor, 4294967296
local function xor(a,b)
    local n,p=0,1
    for _=1,32 do
        local x,y=a%2,b%2
        if x~=y then n=n+p end
        a,b,p=floor(a/2),floor(b/2),p*2
    end
    return n
end
local function band(a,b) return (a+b-xor(a,b))/2 end
local function shr(a,n) return floor(a/2^n) end
local function ror(a,n) return shr(a,n)+(a%2^n)*2^(32-n) end
-- WoW's bit library avoids the arithmetic fallback's per-bit loops.
if bit and bit.bxor and bit.band and bit.rshift and bit.ror then
    xor=function(a,b) return bit.bxor(a,b)%mod end
    band=function(a,b) return bit.band(a,b)%mod end
    shr=function(a,n) return bit.rshift(a,n)%mod end
    ror=function(a,n) return bit.ror(a,n)%mod end
end
local function xor3(a,b,c) return xor(xor(a,b),c) end
local K={
0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
function ZGV:CampaignPayloadHash(input)
    local bytes=#input
    local tail={}
    local length=bytes*8
    for i=8,1,-1 do tail[i]=string.char(length%256);length=floor(length/256) end
    local s=input..string.char(128)..string.rep('\0',(55-bytes)%64)..table.concat(tail)
    local h={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
    for offset=1,#s,64 do
        local w={}
        for i=0,15 do
            local a,b,c,d=s:byte(offset+i*4,offset+i*4+3)
            w[i]=a*16777216+b*65536+c*256+d
        end
        for i=16,63 do
            local a,b=w[i-15],w[i-2]
            w[i]=(w[i-16]+xor3(ror(a,7),ror(a,18),shr(a,3))+w[i-7]+xor3(ror(b,17),ror(b,19),shr(b,10)))%mod
        end
        local a,b,c,d,e,f,g,j=unpack(h)
        for i=0,63 do
            local t1=(j+xor3(ror(e,6),ror(e,11),ror(e,25))+xor(band(e,f),band(mod-1-e,g))+K[i+1]+w[i])%mod
            local t2=(xor3(ror(a,2),ror(a,13),ror(a,22))+xor3(band(a,b),band(a,c),band(b,c)))%mod
            j,g,f,e,d,c,b,a=g,f,e,(d+t1)%mod,c,b,a,(t1+t2)%mod
        end
        local values={a,b,c,d,e,f,g,j}
        for i=1,8 do h[i]=(h[i]+values[i])%mod end
    end
    for i=1,8 do h[i]=string.format('%08x',h[i]) end
    return table.concat(h)
end
