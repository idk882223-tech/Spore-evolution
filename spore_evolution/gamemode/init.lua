AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

util.AddNetworkString("spore_buy")

local FOOD_TARGET = 45   -- сколько еды держим на карте
local FOOD_RADIUS = 2000 -- радиус разброса вокруг точек спавна

local function ResetPlayerData(ply)
	ply:SetNWInt("SporeDNA", 0)
	ply:SetNWInt("SporePoints", 0)
	ply:SetNWInt("SporeStage", 1)
	for key in pairs(GAMEMODE.Upgrades) do
		ply:SetNWInt("up_" .. key, 0)
	end
end

function GM:PlayerInitialSpawn(ply)
	self.BaseClass.PlayerInitialSpawn(self, ply)
	ResetPlayerData(ply)
end

function GM:ApplyStage(ply, heal)
	local st = self.Stages[ply:GetNWInt("SporeStage", 1)]
	local function up(k) return ply:GetNWInt("up_" .. k, 0) end

	ply:SetModelScale(st.scale, 0.5)
	self:ApplyHull(ply)
	ply:SetPlayerColor(st.color:ToVector())
	ply:SetMaxHealth(st.health + up("health") * 25)
	if heal then ply:SetHealth(ply:GetMaxHealth()) end
	ply:SetWalkSpeed(st.walk + up("speed") * 15)
	ply:SetRunSpeed(st.run + up("speed") * 30)
	ply:SetJumpPower(st.jump + up("jump") * 25)
end

function GM:PlayerSpawn(ply, transition)
	self.BaseClass.PlayerSpawn(self, ply, transition)
	self:ApplyStage(ply, true)
end

-- Оставляем инструменты Gmod (физган, тулган) и добавляем "укус"
function GM:PlayerLoadout(ply)
	self.BaseClass.PlayerLoadout(self, ply)
	ply:Give("weapon_crowbar")
	return true
end

function GM:CheckStage(ply)
	local old = ply:GetNWInt("SporeStage", 1)
	local new = self:StageForDNA(ply:GetNWInt("SporeDNA", 0))
	ply:SetNWInt("SporeStage", new)
	if new ~= old then
		self:ApplyStage(ply, new > old)
		if new > old then
			PrintMessage(HUD_PRINTTALK, ply:Nick() .. " эволюционировал до стадии: " .. self.Stages[new].name .. "!")
			ply:EmitSound("buttons/button9.wav")
		end
	end
end

function GM:AddDNA(ply, amount)
	if self.RoundOver or not IsValid(ply) or not ply:Alive() then return end
	local dna = ply:GetNWInt("SporeDNA", 0) + amount
	ply:SetNWInt("SporeDNA", dna)
	ply:SetNWInt("SporePoints", ply:GetNWInt("SporePoints", 0) + amount)
	self:CheckStage(ply)
	if dna >= self.WinDNA then self:Win(ply) end
end

function GM:Win(ply)
	self.RoundOver = true
	PrintMessage(HUD_PRINTCENTER, ply:Nick() .. " победил! Новый раунд через 10 секунд")
	PrintMessage(HUD_PRINTTALK, ply:Nick() .. " достиг вершины эволюции и победил!")
	timer.Simple(10, function()
		GAMEMODE.RoundOver = false
		for _, p in ipairs(player.GetAll()) do
			ResetPlayerData(p)
			p:Spawn()
		end
	end)
end

-- Убийство игрока даёт ДНК, смерть отнимает 25%
function GM:PlayerDeath(victim, inflictor, attacker)
	self.BaseClass.PlayerDeath(self, victim, inflictor, attacker)
	if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
		self:AddDNA(attacker, 5 + victim:GetNWInt("SporeStage", 1) * 3)
	end
	local dna = victim:GetNWInt("SporeDNA", 0)
	dna = dna - math.floor(dna * 0.25)
	victim:SetNWInt("SporeDNA", dna)
	victim:SetNWInt("SporeStage", self:StageForDNA(dna))
end

-- Укус сильнее с улучшением и стадией
function GM:EntityTakeDamage(target, dmg)
	local atk = dmg:GetAttacker()
	if IsValid(atk) and atk:IsPlayer() and target:IsPlayer() then
		dmg:ScaleDamage(1 + atk:GetNWInt("up_bite", 0) * 0.3 + (atk:GetNWInt("SporeStage", 1) - 1) * 0.1)
	end
end

net.Receive("spore_buy", function(_, ply)
	local key = net.ReadString()
	local up = GAMEMODE.Upgrades[key]
	if not up or not ply:Alive() then return end
	local lvl = ply:GetNWInt("up_" .. key, 0)
	local pts = ply:GetNWInt("SporePoints", 0)
	if lvl >= up.max or pts < up.cost then return end
	ply:SetNWInt("SporePoints", pts - up.cost)
	ply:SetNWInt("up_" .. key, lvl + 1)
	GAMEMODE:ApplyStage(ply, false)
end)

-- Спавн еды (ДНК-шарики)
local spawnClasses = { "info_player_start", "info_player_deathmatch", "info_player_terrorist", "info_player_counterterrorist", "gmod_player_start" }

local function RandomFoodPos()
	local points = {}
	for _, c in ipairs(spawnClasses) do table.Add(points, ents.FindByClass(c)) end
	if #points == 0 then return end
	for _ = 1, 10 do
		local base = points[math.random(#points)]:GetPos()
		local ang = math.random() * math.pi * 2
		local p = base + Vector(math.cos(ang), math.sin(ang), 0) * math.random(100, FOOD_RADIUS)
		local tr = util.TraceLine({ start = p + Vector(0, 0, 200), endpos = p - Vector(0, 0, 400), mask = MASK_SOLID_BRUSHONLY })
		if tr.Hit and not tr.StartSolid and util.IsInWorld(tr.HitPos + Vector(0, 0, 24)) then
			return tr.HitPos + Vector(0, 0, 24)
		end
	end
end

timer.Create("spore_food_spawner", 1, 0, function()
	if player.GetCount() == 0 then return end
	local count = #ents.FindByClass("spore_food")
	for _ = 1, 3 do
		if count >= FOOD_TARGET then return end
		local pos = RandomFoodPos()
		if pos then
			local f = ents.Create("spore_food")
			f:SetPos(pos)
			f:Spawn()
			count = count + 1
		end
	end
end)
