--------------------------------
--\\ Services //--
--------------------------------

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

--------------------------------
--\\ Constants //--
--------------------------------

local PlayerGui = Players.LocalPlayer.PlayerGui
local ConfettiGui = PlayerGui:WaitForChild("Confetti")
local ConfettiModule = require(ConfettiGui:WaitForChild("Confetti"))

--------------------------------
--\\ Variables //--
--------------------------------

local Controller = {}

--------------------------------
--\\ Public Functions //--
--------------------------------

function Controller:MidScreenConfetti()
	ConfettiModule.Explode(Vector2.new(700, 100), 50, 5)
end

function Controller:ConfettiFullScreen()
	ConfettiModule.Rain(100)
end

function Controller:ConfettiCustomPoint(point : Vector2)
	ConfettiModule.Explode(point, math.random(75, 100), 5)
end

function Controller:MousePosConfetti()
	local MousePos = UserInputService:GetMouseLocation()
	
	if not MousePos then
		warn(`No mouse pos found!`)
		Controller:MidScreenConfetti()
	else
		Controller:ConfettiCustomPoint(MousePos - Vector2.new(0, 40))
	end
end

function Controller:OnStart()
	print(`ConfettiController Started.`)
end


--------------------------------
--\\ Main //--
--------------------------------

return Controller