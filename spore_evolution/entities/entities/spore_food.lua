AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Spore Food"

function ENT:Initialize()
	if not SERVER then return end
	self:SetModel("models/hunter/misc/sphere025x025.mdl")
	self:SetMaterial("models/debug/debugwhite")
	self:SetColor(HSVToColor(math.random(0, 360), 0.7, 1))
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionBounds(Vector(-14, -14, -14), Vector(14, 14, 14))
	self:SetTrigger(true)
end

if SERVER then
	function ENT:StartTouch(ent)
		if IsValid(ent) and ent:IsPlayer() and ent:Alive() then
			GAMEMODE:AddDNA(ent, 1)
			ent:EmitSound("garrysmod/ui_click.wav", 60, math.random(120, 160))
			self:Remove()
		end
	end
end
