local ZGV = ZygorGuidesViewer
local function state()
	local guide = ZGV.CurrentGuide
	local key = guide and guide.title or ZGV.CurrentGuideName
	return key, key and ZGV.CampaignDisplayTitles and ZGV.CampaignDisplayTitles[key]
end
local lastKey, lastTitle, lastLoading
local watcher = CreateFrame('Frame')
watcher:SetScript('OnUpdate', function()
	local key, title = state()
	if key ~= lastKey or title ~= lastTitle or ZGV.loading ~= lastLoading then
		lastKey, lastTitle, lastLoading = key, title, ZGV.loading
		if key and not ZGV.loading then
			if ZGV:IsRemasterSkin() then ZGV:UpdateRemasterHeader() else ZGV:UpdateLegacyHeaderTitle(title or (ZGV.CurrentGuide and ZGV.CurrentGuide.title_short) or key) end
		end
	end
end)
SLASH_ZGVTITLE1 = '/zgvtitle'
SlashCmdList.ZGVTITLE = function()
	local key, title = state()
	local frame = ZygorGuidesViewerFrame_Border_SectionTitle
	if ZGV:IsRemasterSkin() then frame = ZGV.RemasterFrames and ZGV.RemasterFrames.headerTitle end
	print('Journey title: key='..tostring(key)..' entry='..tostring(title)..' shown='..tostring(frame and frame:GetText()))
end
