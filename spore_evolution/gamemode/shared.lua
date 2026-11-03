DeriveGamemode("sandbox")

GM.Name    = "Spore Evolution"
GM.Author  = "Claude"
GM.Email   = ""
GM.Website = ""

-- ДНК, нужное для победы
GM.WinDNA = 120

-- Стадии развития (как в Spore): чем больше ДНК, тем выше стадия
GM.Stages = {
	{ name = "Клетка",       dna = 0,  scale = 0.35, health = 40,  walk = 150, run = 260, jump = 180, color = Color(120, 255, 140) },
	{ name = "Существо",     dna = 15, scale = 0.70, health = 80,  walk = 160, run = 250, jump = 200, color = Color(255, 210, 90)  },
	{ name = "Племя",        dna = 40, scale = 1.00, health = 120, walk = 170, run = 240, jump = 200, color = Color(255, 140, 80)  },
	{ name = "Цивилизация",  dna = 75, scale = 1.25, health = 180, walk = 180, run = 250, jump = 210, color = Color(120, 180, 255) },
}

-- Улучшения "редактора существа", покупаются за очки эволюции
GM.UpgradeOrder = { "speed", "health", "bite", "jump" }
GM.Upgrades = {
	speed  = { name = "Скорость",   max = 5, cost = 2 },
	health = { name = "Здоровье",   max = 5, cost = 2 },
	bite   = { name = "Сила укуса", max = 5, cost = 3 },
	jump   = { name = "Прыгучесть", max = 5, cost = 1 },
}

function GM:StageForDNA(dna)
	local idx = 1
	for i, st in ipairs(self.Stages) do
		if dna >= st.dna then idx = i end
	end
	return idx
end

-- Хитбокс под размер существа (вызывается и на сервере, и на клиенте)
function GM:ApplyHull(ply)
	local s = self.Stages[ply:GetNWInt("SporeStage", 1)].scale
	ply:SetHull(Vector(-16 * s, -16 * s, 0), Vector(16 * s, 16 * s, 72 * s))
	ply:SetHullDuck(Vector(-16 * s, -16 * s, 0), Vector(16 * s, 16 * s, 36 * s))
	ply:SetViewOffset(Vector(0, 0, 64 * s))
	ply:SetViewOffsetDucked(Vector(0, 0, 28 * s))
end
