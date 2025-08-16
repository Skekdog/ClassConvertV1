local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local StudioService = game:GetService("StudioService")
local GetPlugin = require("../Lib/GetPlugin")

local plugin = GetPlugin

local module = {}

local colourSyncTargets: {GuiObject} = {}

local widget = plugin:CreateDockWidgetPluginGui("ClassConvert", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	true,
	600,
	400,
	600,
	400
	)
)

widget.Name = "Class Convert"
widget.Title = "Class Convert"
widget.ResetOnSpawn = false
widget.Enabled = false

local showDeprecated = plugin:GetSetting("ShowDeprecated") or false
local showNonBrowsable = plugin:GetSetting("ShowNonBrowsable") or false

local frame = Instance.new("Frame")
frame.Transparency = 1
frame.Size = UDim2.fromScale(1, 1)

local function levenshtein(a: string, b: string)
	local len1, len2 = #a, #b
	local matrix = {}

	for i = 0, len1 do
		matrix[i] = {[0] = i}
	end
	for j = 1, len2 do
		matrix[0][j] = j
	end

	for i = 1, len1 do
		for j = 1, len2 do
			local cost = (a:sub(i, i) == b:sub(j, j)) and 0 or 1
			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end
	
	return matrix[len1][len2]
end

do
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.025, 0)
	padding.PaddingRight = UDim.new(0.025, 0)
	padding.PaddingTop = UDim.new(0.025, 0)
	padding.Parent = frame
	
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = frame
	
	local separator = Instance.new("Frame")
	separator.BackgroundColor3 = Color3.new(0, 0, 0)
	separator.Size = UDim2.fromScale(1, 0.01)
	separator.Name = "Separator"
	separator.LayoutOrder = 3
	separator.Parent = frame
	table.insert(colourSyncTargets, separator)
end

local showDeprecatedFrame = Instance.new("Frame")
showDeprecatedFrame.BackgroundTransparency = 1
showDeprecatedFrame.Size = UDim2.fromScale(1, 0.075)
showDeprecatedFrame.LayoutOrder = 1
showDeprecatedFrame.Name = "ShowDeprecated"
showDeprecatedFrame.Parent = frame

local showDeprecatedButton = Instance.new("ImageButton")
showDeprecatedButton.BackgroundTransparency = 1
showDeprecatedButton.Image = if plugin:GetSetting("ShowDeprecated") then "rbxasset://studio_svg_textures/Shared/Utility/Light/Standard/CheckboxOn@3x.png" else "rbxasset://studio_svg_textures/Shared/Utility/Light/Standard/CheckboxOff@3x.png"
showDeprecatedButton.Name = "Checkbox"
showDeprecatedButton.Size = UDim2.fromScale(1, 1)
showDeprecatedButton.Parent = showDeprecatedFrame

do
	local label = Instance.new("TextLabel")
	label.Text = "Show Deprecated"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSans
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Name = "Label"
	label.Parent = showDeprecatedFrame
	label.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(colourSyncTargets, label)
	
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 10)
	list.Parent = showDeprecatedFrame
	
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.DominantAxis = Enum.DominantAxis.Height
	aspectRatio.Parent = showDeprecatedButton
end

local showNonBrowsableFrame = Instance.new("Frame")
showNonBrowsableFrame.BackgroundTransparency = 1
showNonBrowsableFrame.Size = UDim2.fromScale(1, 0.075)
showNonBrowsableFrame.LayoutOrder = 2
showNonBrowsableFrame.Name = "ShowNonBrowsable"
showNonBrowsableFrame.Parent = frame

local showNonBrowsableButton = Instance.new("ImageButton")
showNonBrowsableButton.BackgroundTransparency = 1
showNonBrowsableButton.Image = if showNonBrowsable then "rbxasset://studio_svg_textures/Shared/Utility/Light/Standard/CheckboxOn@3x.png" else "rbxasset://studio_svg_textures/Shared/Utility/Light/Standard/CheckboxOff@3x.png"
showNonBrowsableButton.Name = "Checkbox"
showNonBrowsableButton.Size = UDim2.fromScale(1, 1)
showNonBrowsableButton.Parent = showNonBrowsableFrame

do
	local label = Instance.new("TextLabel")
	label.Text = "Show Non-Browsable"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSans
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Name = "Label"
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = showNonBrowsableFrame
	table.insert(colourSyncTargets, label)

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 10)
	list.Parent = showNonBrowsableFrame

	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.DominantAxis = Enum.DominantAxis.Height
	aspectRatio.Parent = showNonBrowsableButton
end


local searchBar = Instance.new("TextBox")
searchBar.Font = Enum.Font.SourceSans
searchBar.AnchorPoint = Vector2.new(0.5, 0)
searchBar.Position = UDim2.fromScale(0.5, 0)
searchBar.Size = UDim2.fromScale(1, 0.1)
searchBar.Text = ""
searchBar.PlaceholderText = "Search..."
searchBar.TextScaled = true
searchBar.TextXAlignment = Enum.TextXAlignment.Left
searchBar.Name = "SearchBar"
searchBar.ClearTextOnFocus = false
searchBar.Parent = frame
table.insert(colourSyncTargets, searchBar)

do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.4, 0)
	corner.Parent = searchBar
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = searchBar
end

local resultsGrid = Instance.new("ScrollingFrame")
resultsGrid.BackgroundTransparency = 1
resultsGrid.Position = UDim2.new(0, 0, 0.11, 10)
resultsGrid.Size = UDim2.fromScale(1, 0.74)
resultsGrid.CanvasSize = UDim2.fromScale(0, 0)
resultsGrid.ScrollBarThickness = 6
resultsGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
resultsGrid.ScrollingDirection = Enum.ScrollingDirection.Y
resultsGrid.ScrollBarImageColor3 = Color3.new(0, 0, 0)
resultsGrid.BorderSizePixel = 4
resultsGrid.LayoutOrder = 4
resultsGrid.Name = "Results"
resultsGrid.Parent = frame
table.insert(colourSyncTargets, resultsGrid)

do
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromScale(1, 0.1)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = resultsGrid
end

local resultBase = Instance.new("TextButton")
resultBase.Text = ""
resultBase.Name = "Result"

do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25)
	corner.Parent = resultBase
	
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, 5)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = resultBase
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = resultBase
	
	local label = Instance.new("TextLabel")
	label.Font = Enum.Font.SourceSans
	label.TextScaled = true
	label.Size = UDim2.fromScale(1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundTransparency = 1
	label.Name = "Label"
	label.Parent = resultBase
	
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(1, 0.9)
	icon.Image = ""
	icon.Parent = resultBase
	
	do
		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.DominantAxis = Enum.DominantAxis.Height
		aspectRatio.Parent = icon
	end
end

frame.Parent = widget

local apiDump: {}?

do
	local lastVersion = plugin:GetSetting("LastVersion")
	if lastVersion == version() then
		apiDump = plugin:GetSetting("CachedApiDump")
	else
		plugin:SetSetting("LastVersion", version())
	end
end

apiDump = apiDump or HttpService:JSONDecode(HttpService:GetAsync("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json")).Classes
plugin:SetSetting("CachedApiDump", apiDump)

local function fetchProperties(classToCollect: string)
	local props: {string} = {}
	local found = false

	repeat
		found = false
		for _, class in apiDump do
			if class.Name ~= classToCollect then
				continue
			end
			for _, member in class.Members do
				if member.MemberType == "Property" then
					table.insert(props, member.Name)
				end
			end
			classToCollect = class.Superclass
			found = true
		end
		assert(found, "Class not found: "..classToCollect)
	until classToCollect == "<<<ROOT>>>"

	return props
end

local function convert(from: {Instance}, to: string): {Instance}?
	if #from < 1 then
		warn("No selection, conversions will not be made.")
		return nil
	end
	
	local recording = ChangeHistoryService:TryBeginRecording(`Convert classes of selection to {to}`)
	if not recording then
		warn("Unable to create undo waypoint, possibly due to another conversion already taking place. Conversion aborted.")
		return nil
	end
	
	local newSelections: {Instance} = {}
	
	local success = pcall(function() -- In case anything errors we NEED undo to be possible, best not take chances
		for _, instance in from do
			local new: Instance = Instance.new(to)

			for _, v in fetchProperties(instance.ClassName) do
				pcall(function()
					(new :: any)[v] = (instance :: any)[v]
				end)
			end

			for _, v in instance:GetChildren() do
				v.Parent = new
			end
			
			for i, v in instance:GetAttributes() do
				new:SetAttribute(i, v)
			end
			
			for _, v in instance:GetTags() do
				new:AddTag(v)
			end

			instance.Parent = nil -- :Destroy() locks the parent property, which means that undo does not work!
			table.insert(newSelections, new)
		end
	end)
	
	ChangeHistoryService:FinishRecording(recording, if success then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel)
	return newSelections
end

-- CSG classes do not work correctly but they would appear as if they should so we catch this
local invalidClasses = {"UnionOperation", "NegateOperation", "IntersectOperation", "PartOperationAsset"}
local superclasses: {[string]: string?} = {}
for _, class in apiDump do
	local isDeprecated, isNonBrowsable = false, false
	local tags = class.Tags :: {string}?
	if tags then
		if table.find(tags, "NotCreatable") or table.find(tags, "ReadOnly") or table.find(tags, "Service") then
			-- You would think that there is no need to check for "Service" explicitly, but no, HeightmapImporterService exists.
			continue
		end
		if table.find(tags, "Deprecated") then
			isDeprecated = true
		end
		if table.find(tags, "NotBrowsable") then
			isNonBrowsable = true
		end
	end

	if class.Name:sub(1, 18) == "ReflectionMetadata" or table.find(invalidClasses, class.Name) then
		continue
	end
	
	local name = class.Name
	
	local canBeCreated = pcall(function()
		Instance.new(name)
	end)
	
	if not canBeCreated then
		continue
	end

	superclasses[name] = class.Superclass
	
	local result = resultBase:Clone();
	(result:FindFirstChild("Label") :: TextLabel).Text = name
	result:SetAttribute("Deprecated", isDeprecated)
	result:SetAttribute("NonBrowsable", isNonBrowsable)
	result.Name = name
	result.Parent = resultsGrid
	table.insert(colourSyncTargets, result)
	table.insert(colourSyncTargets, result:FindFirstChild("Label") :: TextLabel)
	table.insert(colourSyncTargets, result:FindFirstChild("Icon") :: ImageLabel)
	result.MouseButton1Click:Connect(function()
		local result = convert(Selection:Get(), name)
		if result then
			Selection:Set(result)
		end
	end)
end

local function syncOne(v: GuiObject, theme: any)
	if v:IsA("ImageLabel") then
		local parent = assert(v.Parent, "ImageLabel has no parent")
		local classIcon = StudioService:GetClassIcon(parent.Name)
		v.Image = classIcon.Image
		v.ImageRectOffset = classIcon.ImageRectOffset
		v.ImageRectSize = classIcon.ImageRectSize
	elseif v.Name == "Separator" and v.ClassName == "Frame" then
		v.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	elseif v.Name == "Results" and v.ClassName == "ScrollingFrame" then
		v.BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	else
		assert(v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox"));
		(v :: TextLabel).BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScriptEditorCurrentLine);
		(v :: TextLabel).TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end
end

local function syncColours()
	local theme = settings().Studio.Theme
	for _, v in colourSyncTargets do
		syncOne(v, theme)
	end
end

syncColours()
settings().Studio.ThemeChanged:Connect(syncColours)

local function updateSearch()
	local text = searchBar.Text:lower()
	local visibleElements: {TextButton} = {}
	for _, v in resultsGrid:GetChildren() do
		if not v:IsA("TextButton") then
			continue
		end
		if (not showDeprecated) and v:GetAttribute("Deprecated") then
			v.Visible = false
			continue
		end
		if (not showNonBrowsable) and v:GetAttribute("NonBrowsable") then
			v.Visible = false
			continue
		end
		if v.Name:lower():match(text) then
			v.Visible = true
			table.insert(visibleElements, v)
		else
			v.Visible = false
		end
	end
	
	table.sort(visibleElements, function(a, b)
		return levenshtein(a.Name:lower(), text) < levenshtein(b.Name:lower(), text)
	end)
	
	for i, v in visibleElements do
		v.LayoutOrder = i
	end
end

searchBar:GetPropertyChangedSignal("Text"):Connect(updateSearch)

showDeprecatedButton.MouseButton1Click:Connect(function()
	showDeprecated = not showDeprecated
	plugin:SetSetting("ShowDeprecated", showDeprecated)
	showDeprecatedButton.Image = if showDeprecated then "rbxasset://studio_svg_textures/Shared/Utility/Light/Standard/CheckboxOn@3x.png" else "rbxasset://studio_svg_textures/Shared/Utility/Light/Standard/CheckboxOff@3x.png"
	updateSearch()
end)

showNonBrowsableButton.MouseButton1Click:Connect(function()
	showNonBrowsable = not showNonBrowsable
	plugin:SetSetting("ShowNonBrowsable", showNonBrowsable)
	showNonBrowsableButton.Image = if showNonBrowsable then "rbxasset://studio_svg_textures/Shared/Utility/Light/Standard/CheckboxOn@3x.png" else "rbxasset://studio_svg_textures/Shared/Utility/Light/Standard/CheckboxOff@3x.png"
	updateSearch()
end)

updateSearch()

function module.ToggleWidget(enabled: boolean?): ()
	widget.Enabled = if typeof(enabled) == "boolean" then enabled else not widget.Enabled
end

module.Widget = widget

return module