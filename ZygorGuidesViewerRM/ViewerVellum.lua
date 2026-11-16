-- Presentation only: keep the viewer's existing layout and controls.
local ZGV = ZygorGuidesViewer
if not ZGV then return end

BINDING_NAME_ZYGORGUIDES_OPENSTORY = "Open Story"

local ink = {44/255, 31/255, 16/255, 1}
local titleInk = {90/255, 43/255, 11/255, 1}
local vellum = {210/255, 188/255, 146/255, 1}
local border = {134/255, 104/255, 60/255, 1}
local clear = {0, 0, 0, 0}
local function color(frame, method, values)
	if frame and frame[method] then frame[method](frame, unpack(values)) end
end
local function textStyle(label, font, size, values)
	if not label then return end
	label:SetFont(font, size)
	label:SetTextColor(unpack(values))
	label:SetShadowOffset(0, 0)
end
local function skin()
	if not ZGV.db or not ZGV.db.profile or not ZGV:IsRemasterSkin() then return end
	local f = ZGV.RemasterFrames
	if not f then return end
	color(f.root, 'SetBackdropColor', vellum)
	color(f.root, 'SetBackdropBorderColor', border)
	color(f.content, 'SetBackdropColor', vellum)
	color(f.content, 'SetBackdropBorderColor', border)
	for _, texture in ipairs({f.headerBg, f.toolbarBg, f.footerBg}) do
		color(texture, 'SetTexture', clear)
	end
	color(f.separator, 'SetTexture', border)
	color(f.footerSeparator, 'SetTexture', border)
	textStyle(f.headerTitle, 'Fonts\\MORPHEUS.TTF', 13, titleInk)
	textStyle(f.headerMeta, STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF', 11, ink)
	textStyle(f.stepLabel, STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF', 11, ink)
	textStyle(ZygorGuidesViewerFrame_MissingText, STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF', 11, ink)
	for _, name in ipairs({'guideButton', 'prevButton', 'nextButton', 'closeButton', 'settingsButton', 'miniButton', 'lockButton'}) do
		local button = f[name]
		if button then
			button.remasterBackColor, button.remasterHoverColor, button.remasterBorderColor = vellum, border, border
			color(button, 'SetBackdropColor', vellum)
			color(button, 'SetBackdropBorderColor', border)
		end
	end
end
local function steps()
	if not ZGV.db or not ZGV.db.profile or not ZGV:IsRemasterSkin() then return end
	for _, step in ipairs(ZGV.stepframes or {}) do
		color(step, 'SetBackdropColor', clear)
		if step.border then
			step.border:SetBackdrop({edgeFile='Interface\\Buttons\\white8x8', edgeSize=1})
			color(step.border, 'SetBackdropBorderColor', border)
		end
		for _, line in ipairs(step.lines or {}) do
			local label = line.label
			if label then
				local text = label:GetText()
				if text then
					local toned = text:gsub('|c%x%x%x%x%x%x%x%x', '|cff2c1f10')
					if toned ~= text then label:SetText(toned) end
				end
				local _, size = label:GetFont()
				textStyle(label, STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF', size or 11, ink)
			end
		end
	end
end

hooksecurefunc(ZGV, 'ApplyRemasterSkin', skin)
hooksecurefunc(ZGV, 'UpdateFrame', steps)
