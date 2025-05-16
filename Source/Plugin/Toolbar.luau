local GetPlugin = require("../Lib/GetPlugin")

local plugin = GetPlugin

local module = {}

local toolbar = plugin:CreateToolbar("Class Convert")
local button = toolbar:CreateButton("Convert", "Opens the menu for selecting a new class", "rbxassetid://18845890189")
button.ClickableWhenViewportHidden = true

module.Toolbar = toolbar
module.Button = button
module.OnClick = nil :: () -> ()?

button.Click:Connect(function()
	if module.OnClick then
		module.OnClick()
	end
end)

return module