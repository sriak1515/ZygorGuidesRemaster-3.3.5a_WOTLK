-- Client texture requirements: power-of-two, uncompressed true-colour TGA.
local root=arg[1] or "ZygorGuidesViewerRM"
for _,name in ipairs({"ParchmentPage","ParchmentRule"}) do
    local f=assert(io.open(root.."/Skin/"..name..".tga","rb"))
    local bytes=f:read("*a");f:close()
    assert(bytes:byte(3)==2,"client texture must be uncompressed true-colour TGA")
    local width=bytes:byte(13)+bytes:byte(14)*256
    local height=bytes:byte(15)+bytes:byte(16)*256
    local depth=bytes:byte(17)
    assert(depth==24 or depth==32)
    local function powerOfTwo(n) while n>1 and n%2==0 do n=n/2 end return n==1 end
    assert(powerOfTwo(width) and powerOfTwo(height))
    assert(#bytes>=18+width*height*depth/8,"truncated client texture")
    if name=="ParchmentRule" then assert(depth==32,"ornament needs alpha") end
end
print("PASS: bundled A+ paper and ornament use native-compatible TGA dimensions/encoding")
