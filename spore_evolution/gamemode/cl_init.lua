include("shared.lua")

surface.CreateFont("SporeBig",   { font = "Trebuchet MS", size = 28, weight = 800 })
surface.CreateFont("SporeSmall", { font = "Trebuchet MS", size = 20, weight = 600 })

-- Синхронизируем хитбокс при смене стадии (нужно для предсказания движения)
local lastStage = {}
hook.Add("Think", "SporeHull", function()
	for _, ply in ipairs(player.GetAll()) do
		local st = ply:GetNWInt("SporeStage", 1)
		if lastStage[ply] ~= st then
			lastStage[ply] = st
			GAMEMODE:ApplyHull(ply)
		end
	end
end)

hook.Add("HUDPaint", "SporeHUD", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	local stage = ply:GetNWInt("SporeStage", 1)
	local st    = GAMEMODE.Stages[stage]
	local nxt   = GAMEMODE.Stages[stage + 1]
	local dna   = ply:GetNWInt("SporeDNA", 0)
	local pts   = ply:GetNWInt("SporePoints", 0)

	local w, h = 320, 18
	local cx, y = ScrW() / 2, ScrH() - 90
	local from, to = st.dna, nxt and nxt.dna or GAMEMODE.WinDNA
	local frac = math.Clamp((dna - from) / (to - from), 0, 1)

	draw.SimpleTextOutlined(st.name, "SporeBig", cx, y - 28, st.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	draw.RoundedBox(6, cx - w / 2, y, w, h, Color(0, 0, 0, 170))
	draw.RoundedBox(6, cx - w / 2, y, w * frac, h, st.color)
	draw.SimpleTextOutlined("ДНК " .. dna .. " / " .. to, "SporeSmall", cx, y + h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	draw.SimpleTextOutlined("Очки эволюции: " .. pts .. "   (F2 — улучшения)", "SporeSmall", cx, y + h + 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end)

local function ToggleMenu()
	if IsValid(SporeMenu) then SporeMenu:Remove() return end

	local f = vgui.Create("DFrame")
	SporeMenu = f
	f:SetTitle("Редактор существа")
	f:SetSize(380, 80 + #GAMEMODE.UpgradeOrder * 54)
	f:Center()
	f:MakePopup()

	local lbl = vgui.Create("DLabel", f)
	lbl:SetPos(12, 32)
	lbl:SetSize(350, 20)
	lbl.Think = function(s) s:SetText("Очки эволюции: " .. LocalPlayer():GetNWInt("SporePoints", 0)) end

	local y = 60
	for _, key in ipairs(GAMEMODE.UpgradeOrder) do
		local up = GAMEMODE.Upgrades[key]
		local btn = vgui.Create("DButton", f)
		btn:SetPos(10, y)
		btn:SetSize(360, 48)
		btn.Think = function(s)
			local lp = LocalPlayer()
			local lvl = lp:GetNWInt("up_" .. key, 0)
			s:SetText(string.format("%s   [%d/%d]   цена: %d", up.name, lvl, up.max, up.cost))
			s:SetEnabled(lvl < up.max and lp:GetNWInt("SporePoints", 0) >= up.cost)
		end
		btn.DoClick = function()
			net.Start("spore_buy")
			net.WriteString(key)
			net.SendToServer()
		end
		y = y + 54
	end
end

hook.Add("PlayerButtonDown", "SporeMenuKey", function(_, key)
	if key == KEY_F2 and IsFirstTimePredicted() then ToggleMenu() end
end)
concommand.Add("spore_menu", ToggleMenu)
