-- m_vecSegmentStartPoint will be previous path (when AdvancePath() is called, it will be around GetPos()) 
-- m_vecSegmentStartSplinePoint will be GetCurWaypointPos() 
AddCSLuaFile() 

ENT.Base			= "base_ai" 
ENT.Type 			= "ai" 
ENT.PrintName		= "Unreal Apache" 
ENT.Author			= "DevilHawk" 
ENT.Spawnable		= false 

ENT.maxhealth = 400 
ENT.UApache_FoV = -0.707 

local function AddNPC( t, class ) 
	list.Set( "NPC", class or t.Class, t ) 
end 

local model = Model("models/vehicles/ut99/unrealapachev3.mdl") 
local flysound = Sound("^misc/ut99/apachesnd.wav") -- looping sound when apache starts 
-- local flysound = Sound("NPC_UApache.FlySound") 
local flyalarmsound = Sound("unreal/amb/alarm2.wav") -- looping sound when apache is critically damaged 
local spawnsound = Sound("misc/ut99/pilot1.wav") -- first snd when apache starts 
local base64_model = 1234 
local uapache_damageresist = 0.3 
local HELICOPTER_GRAVITY	= 384 
local HELICOPTER_DT		= 0.1 
local HELICOPTER_MIN_DZ_DAMP	= -500.0 
local HELICOPTER_MAX_DZ_DAMP	= -1000.0 
local HELICOPTER_FORCE_BLEND = 0.8 
local HELICOPTER_FORCE_BLEND_VEHICLE = 0.2 
local HELICOPTER_SPEED = 500 
local HELICOPTER_ACCEL_RATE	=		500 
local HELICOPTER_LEAD_DISTANCE	=	800
local HELICOPTER_MIN_CHASE_DIST_DIFF	=	128 -- Distance threshold used to determine when a target has moved enough to update our navigation to it
local HELICOPTER_MIN_AGGRESSIVE_CHASE_DIST_DIFF	=	64
local HELICOPTER_AVOID_DIST	=	512
local HELICOPTER_ARRIVE_DIST	=	128

local	UAPACHE_FLY_PHOTO	= 1		-- Fly close to photograph entity
local	UAPACHE_FLY_PATROL	= 2		-- Fly slowly around the enviroment
local	UAPACHE_FLY_FAST	= 3		-- Fly quickly around the enviroment
local	UAPACHE_FLY_CHASE	= 4		-- Fly quickly around the enviroment
local	UAPACHE_FLY_SPOT	= 5		-- Fly above enity in spotlight position
local	UAPACHE_FLY_ATTACK	= 6		-- Get in my enemies face for spray or flash
local	UAPACHE_FLY_DIVE	= 7		-- Divebomb - only done when dead
local	UAPACHE_FLY_FOLLOW	= 8		-- Following a target 

AddNPC( { 
	Name = "Unreal Apache 2", 
	Class = "npc_uapache_beta", 
	Category = "Unreal Tournament", 
	
	-- Spawnflags used:
	-- 2: Gag
	-- 65536 : No Dynamic Light
	-- 131072 : Strider Scout Scanner
	
	Model = model, 
}, "Unreal Apache 2" ) 


ENT.bNewPath = false 
ENT.m_bChooseFarthestPoint = false 
ENT.m_flGoalRollDmg = 0 
ENT.m_fHeadYaw = 0 
ENT.m_fMaxYawSpeed = 0 -- Max turning speed 
ENT.m_flCurrPathOffset = 0 
ENT.m_flFarthestPathDist = 16384 
ENT.m_flGoalOverrideDistance = 0 
ENT.m_flTargetTolerance = 128 
ENT.m_flTargetDistanceThreshold = HELICOPTER_MIN_CHASE_DIST_DIFF 
ENT.m_flForce = 0 
ENT.m_nFlyMode = 2 
ENT.m_pSmokeTrail = NULL 
ENT.m_vCurrentBanking = angle_zero 
ENT.m_vCurrentVelocity = Vector(0,0,0)  
ENT.m_vNoiseMod = Vector(0,0,0)  
ENT.m_vecAngAcceleration = Angle()  
ENT.m_vecTargetPosition = Vector(0,0,0)  
ENT.UApache_Near_Dist = 150 
ENT.UApache_Far_Dist = 300 
ENT.UApache_Attack_Range = 350 
ENT.UApache_Max_Speed = 500 
ENT.UApache_Squad_Fly_Dist	= 500 

ENT.Pitch_Modifier = 0 
ENT.PhysicsSolidMask = MASK_SOLID + CONTENTS_HITBOX 

local tableofbulletproof = {
		["npc_helicopter"]=true,
		["npc_combinegunship"]=true,
		["npc_combinedropship"]=true,
		["npc_vehicledriver"]=true,
		["npc_apcdriver"]=true
		}
		
local tableofnotrealowners = {
		["npc_template_maker"]=true,
		["npc_maker"]=true,
		["point_template"]=true,
		["point_spotlight"]=true,
		["npc_helicoptersensor"]=true
		}
		
local tableofrocketsonly = {
		["npc_strider"]=true,
		["npc_turret_floor"]=true,
		["monster_alien_controller"]=true,
		["proto_sniper"]=true
		}

local tableofcprojectiles = {
		["apc_missile"]=true,
		["baseprojectile"]=true,
		["bmortar"]=true,
		["bounce_bomb"]=true,
		["combine_bouncemine"]=true,
		["combine_mine"]=true,
		["controller_energy_ball"]=true,
		["controller_head_ball"]=true,
		["crossbow_bolt"]=true,
		["crossbow_bolt_hl1"]=true,
		["env_laserdot"]=true,
		["env_flare"]=true,
		["garg_stomp"]=true,
		["grenade"]=true,
		["grenade_ar2"]=true,
		["grenade_beam"]=true,
		["grenade_hand"]=true,
		["grenade_helicopter"]=true,
		["grenade_homer"]=true,
		["grenade_mp5"]=true,
		["grenade_pathfollower"]=true,
		["grenade_spit"]=true,
		["hornet"]=true,
		["hunter_flechette"]=true,
		["monster_mortar"]=true,
		["monster_satchel"]=true,
		["monster_snark"]=true,
		["monster_tripmine"]=true,
		["mortarshell"]=true,
		["nihilanth_energy_ball"]=true,
		["npc_contactgrenade"]=true,
		["npc_concussiongrenade"]=true,
		["npc_handgrenade"]=true,
		["npc_grenade_frag"]=true,
		["npc_satchel"]=true,
		["npc_tripmine"]=true,
		["rpg_missile"]=true,
		["rpg_rocket"]=true,
		["simple_physics_brush"]=true,
		["simple_physics_prop"]=true,
		["sniperbullet"]=true,
		["squidspit"]=true,
		["physics_cannister"]=true,
		["physics_prop"]=true,
		["prop_physics"]=true,
		["prop_physics_multiplayer"]=true,
		["prop_physics_override"]=true,
		["prop_physics_respawnable"]=true,
		["prop_stickybomb"]=true,
		["weapon_striderbuster"]=true
		}

local function FindEntityNamed(ent)
	local ent2 = ents.FindByName(ent) 
	return ent2[1] 
end 

-- the local math library is brought to you by chatgpt 

local function ExponentialDecay( decayTo, decayTime, dt) 
	return math.exp(math.log( decayTo ) / decayTime * dt) 
end 

local function anglemod(a) 
	b = a*(65536/360) 
	b = bit.band(b,65535) 
	a = (360/65536) * b 
	return a 
end 

local function SimpleSpline(value) return (3 * (value * value) - 2 * (value * value) * value) end 

local function SimpleSplineRemapVal(val, A, B, C, D)
    if A == B then
        return val >= B and D or C
    end
    
    local cVal = (val - A) / (B - A)
    return C + (D - C) * SimpleSpline(cVal)
end 

local function SimpleSplineRemapValClamped(val, A, B, C, D)
    if A == B then
        return val >= B and D or C
    end

    local cVal = (val - A) / (B - A)
    cVal = math.Clamp(cVal, 0.0, 1.0)
    
    return C + (D - C) * SimpleSpline(cVal)
end 

local function ClampSplineRemapVal(flValue, flMinValue, flMaxValue, flOutMin, flOutMax)
    -- Assert that flMinValue is less than or equal to flMaxValue
    -- assert(flMinValue <= flMaxValue, "flMinValue must be less than or equal to flMaxValue")

    -- Clamp the value between the minimum and maximum values
    local flClampedVal = math.Clamp(flValue, flMinValue, flMaxValue)

    -- Remap the clamped value using SimpleSplineRemapVal
    return SimpleSplineRemapVal(flClampedVal, flMinValue, flMaxValue, flOutMin, flOutMax)
end

local function CalcClosestPointToLineT(P, vLineA, vLineB)
    local vDir = vLineB - vLineA -- Direction vector between vLineA and vLineB
    
    -- Compute the dot product of vDir with itself (vDir.Dot(vDir))
    local div = vDir:Dot(vDir)
    
    -- Handle degenerate case (if the line is too short or essentially a point)
    if div < 0.00001 then
        return 0, vDir -- Return t = 0 if the line segment length is effectively 0
    else
        -- Compute the t value using the formula
        return (vDir:Dot(P) - vDir:Dot(vLineA)) / div, vDir 
    end
end 

local function CatmullRomSplineTangent(p1, p2, p3, p4, t) 
    -- Ensure that p1, p2, p3, p4 are distinct from output in the original function 

    -- Initialize the output vector to zero 
    local output = Vector(0, 0, 0) 

    -- Helper constants 
    local tOne = 3 * t * t * 0.5 
    local tTwo = 2 * t * 0.5 
    local tThree = 0.5 

    -- Helper function for scaling vectors 
    local function VectorScale(v, scale) 
        return v * scale 
    end 

    -- Helper function for adding vectors 
    local function VectorAdd(v1, v2) 
        return v1 + v2 
    end 

    -- Matrix row 1: 0.5 t^3 * [ (-1*p1) + ( 3*p2) + (-3*p3) + p4 ] 
    output = VectorAdd(output, VectorScale(p1, -tOne)) 
    output = VectorAdd(output, VectorScale(p2, tOne * 3)) 
    output = VectorAdd(output, VectorScale(p3, tOne * -3)) 
    output = VectorAdd(output, VectorScale(p4, tOne)) 

    -- Matrix row 2: 0.5 t^2 * [ ( 2*p1) + (-5*p2) + ( 4*p3) - p4 ] 
    output = VectorAdd(output, VectorScale(p1, tTwo * 2)) 
    output = VectorAdd(output, VectorScale(p2, tTwo * -5)) 
    output = VectorAdd(output, VectorScale(p3, tTwo * 4)) 
    output = VectorAdd(output, VectorScale(p4, -tTwo)) 

    -- Matrix row 3: 0.5 t * [ (-1*p1) + p3 ] 
    output = VectorAdd(output, VectorScale(p1, -tThree)) 
    output = VectorAdd(output, VectorScale(p3, tThree)) 

    return output 
end 

-- a = bit.band(a,65535)

function ENT:Initialize() 
	if SERVER then -- server realm first 
		if !IsValid(self) then return end -- not precache 
		self:SetModel(model) 
		self:SetMaxHealth(self.maxhealth) 
		self:SetHealth(self.maxhealth) 
		self:SetSaveValue("speed", 500) 
		self:SetSaveValue("m_flFieldOfView", self.UApache_FoV) 
		self:SetNPCClass(CLASS_SCANNER) 
		self:CapabilitiesAdd(CAP_MOVE_FLY) 
		self:CapabilitiesAdd(CAP_SQUAD) 
		self:CapabilitiesAdd(CAP_TURN_HEAD) 
		self:CapabilitiesAdd(CAP_SKIP_NAV_GROUND_CHECK) 
		self:CapabilitiesAdd(CAP_INNATE_RANGE_ATTACK1) 
		self:SetMoveType(MOVETYPE_FLY) 
		self:SetSchedule(SCHED_ALERT_SCAN) 
		self:SetSolid(SOLID_BBOX) 
		self:SetHullType(HULL_LARGE_CENTERED) 
		self:SetHullSizeNormal() 
				-- local meta = getmetatable(self) 
				-- meta.Classify = UApache_Classify 
		self:AddEFlags(EFL_NO_PHYSCANNON_INTERACTION) 
		self:AddEFlags(EFL_NO_MEGAPHYSCANNON_RAGDOLL) 
		self:AddEFlags(EFL_NO_DISSOLVE) 
		self:AddEFlags(EFL_DONTWALKON) 
		self:AddEFlags(EFL_NO_WATER_VELOCITY_CHANGE) 
		self:AddFlags(FL_FLY) 
		self:AddFlags(FL_GRENADE) 
		self:AddFlags(FL_NPC) 
		self:AddFlags(FL_OBJECT) 
		self:AddSolidFlags(FSOLID_NOT_STANDABLE) 
		self:SetCollisionGroup(COLLISION_GROUP_VEHICLE) 
		self:SetMoveCollide(MOVECOLLIDE_FLY_CUSTOM) 
				-- booleans to enable/disable features below
		self.projectile_dodge_enabled = false 
		self.enemy_aim_dodge_enabled = true 
		self.warhead_enabled = true 
		self.rockets_enabled = true 
		self.rotorwash_enabled = true 
		self:SetNavType(NAV_FLY) 
		local mins, maxs = self:GetModelBounds() 
		self:SetCollisionBounds(mins * 0.5, maxs * 0.5) 
		self:SetSurroundingBoundsType(BOUNDS_HITBOXES) 
				-- values that actively used by apache go below
		self.enemynum = nil 
		self.enemypos = nil 
		self.countdownstarted = 0 
		self.pingcountdown = 0 
		self.lastshot = 0 
		self.projtype = "uatracer" 
		self.projtype_2 = self.projtype 
		self.projfired = false 
		self.wpn_switch_waiting = false 
		self.dodgeavailable = 1 
		self.dodgeleft = 0 
		self.dodgeright = 0 
		self.avoidsky_hasbullseye = false 
		self.isdying = false 
		self.m_vecSegmentStartPoint = self:GetPos() 
		self.m_vecSegmentStartSplinePoint = self:GetPos() 
		self.m_flCurrPathOffset = 0 
		self.m_flRandomOffsetTime = 0 
		self.m_vecRandomOffset = Vector() 
		self.m_vecDesiredPosition = self:EyePos() 
		self.attacker = self 
		self.inflictor = self 
		self:SetNWBool("hassmoketrail",false) 
		self:SetSaveValue("m_flDistTooFar",16384) 
		local phys = self:GetPhysicsObject() 
		if IsValid(phys) then 
				phys:SetMass(400) 
		end 
		--[[ 
		self.aisound = ents.Create("ai_sound") -- alert non combine selfs that we're here
		self.aisound:SetPos(self:GetPos()) 
		self.aisound:SetKeyValue("volume", 9999) 
		self.aisound:SetKeyValue("duration", 10) 
		self.aisound:SetKeyValue("soundtype", 2) 
		self.aisound:SetKeyValue("soundcontext", 67108864) 
		self.aisound:SetParent(self) 
		self.aisound:SetOwner(self) 
		self.aisound:SetName(self:EntIndex()..self.aisound:EntIndex()) 
		self.aisound:Spawn() 
		self:DeleteOnRemove(self.aisound) 
		self.aisound.pingnow = CurTime() 
		--]] 
		if self.rotorwash_enabled then 
			self.rotorwash = ents.Create("env_rotorwash_emitter") 
			self.rotorwash:SetPos(self:GetPos()) 
			self.rotorwash:SetParent(self) 
			self.rotorwash:SetOwner(self) 
			self.rotorwash:SetKeyValue("altitude", 500) 
			self.rotorwash:Spawn() 
			self:DeleteOnRemove(self.rotorwash) 
		end 
	end
	if CLIENT then 
		self.usedoppler = true 
		self:SetNWBool("hassmoketrail",false) 
		self.rotorsound = CreateSound(self, flysound) 
		self.rotorsound:SetSoundLevel(105) 
		self.rotorsound:Play() 
		self:EmitSound(spawnsound) 
	end 
end 

local function CalcClosestPointOnLine(P,vLineA, vLineB) 
	local t, vDir = CalcClosestPointToLineT(P, vLineA, vLineB) 
	local vClosest = vLineA + vDir * t -- Closest point on the line 
    
	return vClosest, t -- Return both the closest point and the t val 
end 

function ENT:Think( ) 
	if CLIENT then 
		if self.rotorsound then self.rotorsound:ChangePitch(self:CalcDoppler()+self.Pitch_Modifier) end 
		return 
	end 
	self:UApache_Think( ) 
	debugoverlay.Line(self.m_vecSegmentStartPoint, self.m_vecSegmentStartSplinePoint) 
	-- UApache_Progress_Fly_Path() 
	-- self:UApache_Simulate() -- flight and banking 
	-- self:SetLocalVelocity(self.m_vCurrentVelocity) 
	-- self:SetLocalAngularVelocity(self.m_vCurrentBanking*0.01) 
	-- self:NextThink(CurTime()+0.1) 
	-- return true 
end 

function ENT:StartTouch(ent) 
	if ent:IsWorld() then 
		local tr = self:GetTouchTrace() 
		local vel = self:GetVelocity() - 2 * self:GetVelocity():Dot(tr.HitNormal) * tr.HitNormal 
		self:SetLocalVelocity(vel) 
		self.tempVelocity = self:GetAbsVelocity() 
	else 
		self.tempVelocity = self:GetAbsVelocity() 
		self:SetLocalVelocity(self:GetAbsVelocity()) 
	end 
end 

function ENT:EndTouch(ent) self:SetLocalVelocity(self.tempVelocity) end 

function ENT:GetCrashPoint() return NULL end 

function ENT:UApache_Think() 
	if !IsValid(self) then return end
	-- UApache_CheckifClear(self)
	self:SetSaveValue("speed", 500)
	-- if IsValid(self.aisound) and self.aisound.pingnow < CurTime() then self.aisound:Fire("emitaisound") self.aisound.pingnow = CurTime() + 10 end
	-- self:UApache_PathFind()	-- Pathfinding on maps without air nodes
	if self.projectile_dodge_enabled then self:UApache_DecideShouldDodge() end
	-- self:UApache_FixGoingUpwards()
	
	if !self.smoke_trail_entity then self:UApache_FindSmokeTrail() end
	
	--[[ 
	local tr = util.QuickTrace(
	self:GetPos(),
	Vector(0,0,200),
	self
	)
	if tr.HitSky then 
		UApache_AvoidSky(self)
		-- print("UApache Avoid sky triggered", tr.HitPos)
	end
	--]] 
	
	if self.enemy_aim_dodge_enabled and self:HasCondition(28) and !self:HasCondition(72) then
		self:UApache_SlowDodge()
	end
	
	if IsValid(self:GetPhysicsObject()) and self:Health() > 0 then
		self.physlocalangularvelocity = self:GetPhysicsObject():GetAngleVelocity():Angle()
	end
	
	-- if (self:Health() < 1 or self:GetSaveTable().m_nFlyMode == 6) and !self.isdying then 
		-- self:UApache_DyingThink() 
		-- self:UApache_SetDyingCollision() 
	-- end 
	self:SetSaveValue("m_flSpeed",500) 

	if !IsValid(self:GetEnemy()) then return end -- rest of the script will not go on if there's no enemy 
	self:UApache_WeaponDecision()	
	timer.Simple(1, function()
		-- todo: use arbitrary aimpos if there's no enemy
		if IsValid(self) and !self.projfired then 
			self:UApache_RangeAttack() 
		end 
	end) 	
end 

function ENT:NPC_GetEnemyVehicle(enemy) 
	enemy = IsValid(enemy) and enemy or self:GetEnemy() 
	if !IsValid(enemy) then return NULL end 
	local parentEnt = IsValid(enemy:GetParent()) and enemy:GetParent() or enemy.GetVehicle and IsValid(enemy:GetVehicle()) and enemy:GetVehicle() or NULL 
	return parentEnt
end 

function ENT:NPC_AdjustForMovementDirection(pPath) 
	local prevPath = self:NPC_GetPreviousPath(pPath) 
	if !self.m_bMovingForward and IsValid(prevPath) then return prevPath end 
	return pPath 
end 

function ENT:UApache_RangeAttack() 
	if self.wpn_switch_waiting == true then return end
	if self.isdying then return end 
	if !IsValid(self:GetEnemy()) then return end
	local gun1vector = self:GetAttachment(3)
	local gun2vector = self:GetAttachment(4)
	local rocket1vector = self:GetAttachment(5)
	local rocket2vector = self:GetAttachment(6)
	local warhead1vector = self:GetAttachment(7)
	local warhead2vector = self:GetAttachment(8)
	local randomvector = Vector( math.random(0,1), math.random(0,1), math.random(0,50) )
	local aimpos1 = ((self:GetEnemy():WorldSpaceCenter()+randomvector)-gun1vector.Pos):Angle()
	-- lua_run Entity(1):SetVelocity((Entity(189):GetPos()-Entity(1):GetPos()):GetNormalized()*500)
	local aimpos2 = ((self:GetEnemy():WorldSpaceCenter()+randomvector)-rocket1vector.Pos):Angle()
	local aimpos3 = ((self:GetEnemy():WorldSpaceCenter()+randomvector)-warhead1vector.Pos):Angle()
	if self.projtype == "uatracer" then 
		-- NPC_FireProjectile("uatracer",gun1vector.Pos,self,aimpos1,4000,1) 
		-- NPC_FireProjectile("uatracer",gun2vector.Pos,self,aimpos1,4000,1) 
		local proj = self:NPC_FireProjectile("uatracer",gun1vector.Pos,self,nil,4000,1) 
		local proj2 = self:NPC_FireProjectile_CopyFrom(proj,gun2vector.Pos) 
		local glow1 = ents.Create( "env_sprite" ) 
		glow1:SetKeyValue( "rendercolor","255 255 255" ) 
		glow1:SetKeyValue( "glowProxySize","2.0" ) 
		glow1:SetKeyValue( "HDRColorScale","2.0" ) 
		glow1:SetKeyValue( "renderfx","14" ) 
		glow1:SetKeyValue( "rendermode","3" ) 
		glow1:SetKeyValue( "renderamt","255" ) 
		glow1:SetKeyValue( "disablereceiveshadows","0" ) 
		glow1:SetKeyValue( "model","sprites/ut99/rocketflare.vmt" ) 
		glow1:SetKeyValue( "scale","1" ) 
		glow1:Spawn() 
		glow1:SetPos( gun1vector.Pos ) 
					
		local glow2 = ents.Create( "env_sprite" ) 
		glow2:SetKeyValue( "rendercolor","255 255 255" ) 
		glow2:SetKeyValue( "glowProxySize","2.0" ) 
		glow2:SetKeyValue( "HDRColorScale","2.0" ) 
		glow2:SetKeyValue( "renderfx","14" ) 
		glow2:SetKeyValue( "rendermode","3" ) 
		glow2:SetKeyValue( "renderamt","255" ) 
		glow2:SetKeyValue( "disablereceiveshadows","0" ) 
		glow2:SetKeyValue( "model","sprites/ut99/rocketflare.vmt" ) 
		glow2:SetKeyValue( "scale","1" ) 
		glow2:Spawn() 
		glow2:SetPos( gun2vector.Pos ) 
		timer.Simple(0.1, function () SafeRemoveEntity(glow1) SafeRemoveEntity(glow2) end) 
		elseif self.projtype == "unrealapacheheatseekerv2" then 
		local proj = self:NPC_FireProjectile("unrealapacheheatseekerv2",warhead1vector.Pos,self,aimpos1,1200,1) 
		local proj2 = self:NPC_FireProjectile_CopyFrom(proj,warhead2vector.Pos) 
		elseif self.projtype == "unrealapacherocketsv2" then 
		local proj = self:NPC_FireProjectile("unrealapacherocketsv2",rocket1vector.Pos,self,aimpos1,1550,1) 
		local proj2 = self:NPC_FireProjectile_CopyFrom(proj,rocket2vector.Pos) 
	end 
	self.projfired = true 
	self.countdownstarted = 1 
	self.lastshot = Lerp(0.8,self.lastshot,CurTime()) 
	timer.Simple(0.16, function () self.projfired = false end) 
end 

function ENT:UApache_FindSmokeTrail()
	for k,v in pairs(ents.FindByClass("env_smoketrail")) do
		if v:GetParent() == self then
			self.smoke_trail_entity = v
			self.smoke_trail_entity:SetKeyValue("opacity",1)
			self.smoke_trail_entity:SetKeyValue("maxspeed",100)
			self.smoke_trail_entity:SetKeyValue("endsize",500)
			self.smoke_trail_entity:SetKeyValue("lifetime",5)
			self:SetNWBool("hassmoketrail", true)
		end
	end
end 

function ENT:UApache_Die() 
	if SERVER then 
		for k,v in pairs(ents.FindByClass("ai_hint")) do -- cleanup hint nodes used during pathfinding 
			if v:GetName() == self:EntIndex()..'_uapache_hint' then 
				SafeRemoveEntity(v) -- cleanup hint nodes 
			end 
		end 
		if self:Health() < 1 then -- always shockwave explode on death 
			local exp = ents.Create("unrealapacheshockwave") 
			exp:SetPos(self:GetPos()) 
			exp:SetOwner(self) 
			exp:Spawn() 
		end 
	end 
	if CLIENT then if self.rotorsound then self.rotorsound:Stop() end if self.alarmsound then self.alarmsound:Stop() end end 
end 

function ENT:UApache_WeaponDecision()
	if self.warhead_enabled and (self:UApache_Cond_Boss_Enemy(self) or self:GetSaveTable().m_flSumDamage > 50) then
		self.projtype = "unrealapacheheatseekerv2" -- Kill bosses 
	elseif self.rockets_enabled and (self:UApache_Cond_Tank_Enemy(self) or self:GetSaveTable().m_flSumDamage > 25 or self:UApache_Above_Speedlimit()) then 
		self.projtype = "unrealapacherocketsv2" -- Rockets create danger sounds. ai_sound soundtype = 8
	else 
		self.projtype = "uatracer" -- Against humans, fair weapon. 
	end
	if self.projtype_2 != self.projtype and self.wpn_switch_waiting == false then -- UApache will stop firing while deciding weapons
		self.wpn_switch_waiting = true
		-- print("UApache is now waiting")
		timer.Simple(1, function() if self then self.projtype_2 = self.projtype self.wpn_switch_waiting = false end end)
	end	
end	

function ENT:UApache_Cond_Tank_Enemy()	
--
--Bulletproof enemies like tanks or turrets and smaller enemies such as houndeyes, headcrabs or vehicles will be blasted with eightball missiles.
--
	if (self:GetEnemy():IsValid() and self:GetEnemy():OBBMaxs().Z < 25) or tableofrocketsonly[self:GetEnemy():GetClass()] or self:GetEnemy():GetMoveType() == MOVETYPE_VPHYSICS or (self:GetEnemy():IsPlayer() and IsValid(self:GetEnemy():GetVehicle())) then
		return true
	else
		return false
	end
end	

function ENT:UApache_Cond_Boss_Enemy()	
-- 
-- NPC's that are huge bosses or helicopters will be shockwaved multiple times if we are not so close. for example: npc_helicopter, npc_combinegunship, boss npcs etc..
-- 
	if (tableofbulletproof[self:GetEnemy():GetClass()] or ( self:GetEnemy():IsFlagSet(FL_FLY) or self:GetEnemy().Author == "Juggernaughty" ) or (isfunction( self:GetEnemy().CapabilitiesGet ) and self:GetEnemy():CapabilitiesGet() == CAP_MOVE_FLY) or self:GetEnemy():OBBMaxs().Z > 100)  and (!tableofrocketsonly[self:GetEnemy():GetClass()]  and self:GetPos():DistToSqr(self:GetEnemy():GetPos()) > 2015033) then
		return true 
	else
		return false
	end
end	

function ENT:UApache_Above_Speedlimit() 
	-- This will check if the projectile about to be launched is above speed limits. 
	-- The speed limit causes trouble on how projectile flies up in air
	-- and even, always miss the target.
	local maxspeed = cvars.Number("sv_maxvelocity") 
	local velocity = (self:GetEnemy():WorldSpaceCenter() - self:GetPos()):Angle():Forward() * 4000 
	-- print("Estimated velocity: ", velocity) 
	if (velocity.x > maxspeed or velocity.x < -maxspeed) or (velocity.y > maxspeed or velocity.y < -maxspeed) or (velocity.z > maxspeed or velocity.z < -maxspeed) then 
		-- print("returned true")
		return true 
	else 
		-- print("returned false")
		return false 
	end 
end 

function ENT:UApache_SlowDodge() 
-- Purpose: Sway left or right when an enemy is aiming at uapache. 
-- Dumped because this caused dumb movement on scanner after the enemy was killed. 
-- The scanner was going straight up and I couldn't prevent this
	local phys=self:GetPhysicsObject()
	if self.dodgeavailable == 1 and phys:IsValid() then
		if self.dodgeright == 1 then
			self:SetVelocity(self:GetVelocity()+self:GetRight()*5)
			-- print("dodging to right")
			elseif self.dodgeleft == 1 then
			self:SetVelocity(self:GetVelocity()+self:GetRight()*-5)
			-- print("dodging to left")
		end
	end
end 

function ENT:UApache_DecideShouldDodge() -- similar to ut99 gasbag dodge
	for _,b in pairs(ents.FindInCone( self:GetPos(), self:GetForward() * 1024, 500, math.cos( math.rad( 15 ) ) )) do
		if (b:GetMoveType() == MOVETYPE_FLYGRAVITY 
			or
			b:GetMoveType() == MOVETYPE_FLY
			or 
			b:GetMoveType() == MOVETYPE_VPHYSICS -- all objects that can move
			or 
			b:GetCollisionGroup() == 13 or -- projectile
			b:GetCollisionGroup() == 24 or -- combine ball
			tableofcprojectiles[b:GetClass()]) 
		and 
			(IsValid(b:GetOwner()) -- projectiles fired usually have an owner
			or 
			IsValid(b:GetSaveTable().m_hThrower)) 
		and 
		(b:GetOwner() != self ) -- not fired from uapache
		and
		(self:Disposition(b:GetOwner()) != D_LI or self:Disposition(b) != D_NU) -- not fired from anything you do not see as enemy
		and 
		b:GetClass() != "npc_utbattleship_hyperblast" -- spawned by hyperblast 
		and 
		!b:GetVelocity():IsZero() -- projectiles move
		and 
		!tableofnotrealowners[b:GetOwner()] -- stuff like npc_template_maker
			-- or 
			-- self:HasCondition(28) -- enemy is looking at me
		then 		
			-- print(b:GetClass(), "'s owner is:", b:GetOwner(), "and apache is:", self)
			-- if self:HasCondition(28) then print("I have the enemy looking at me cond!") end
			self:UApache_Dodge(self:WorldToLocal(b:GetPos()))
			if !IsValid(self:GetEnemy()) then self:SetEnemy(b:GetOwner()) end	
		end
	end
end 

function ENT:UApache_Dodge(vec) -- checked in 1 sep 2020: code is wrong 
-- Purpose: Dodges the UApache sideways when a projectile is approaching, depends on where the projectile is.
	if self.isdying then return end 
	local phys = self:GetPhysicsObject() 
	if self.dodgeavailable == 1 and IsValid(phys) then 
		if allvectors then table.Empty(allvectors) end 
		local allvectors = ({ }) -- create table 
		table.insert(allvectors, {vector = vec.y}) 
		table.SortByMember(allvectors,"vec.y",true)
		if allvectors and allvectors[1].vector then
			if allvectors[1].vector > 1 and self:UApache_IsClear(Vector(0,200,0)) == true then
				self.dodgeright = 1
				self.dodgeleft = 0
				-- print("y is higher than 1:",allvectors[1].vector)
			elseif allvectors[1].vector < 1 and self:UApache_IsClear(Vector(0,-200,0)) == true then
				self.dodgeright = 0
				self.dodgeleft = 1
				-- print("y is lesser than 1:",allvectors[1].vector)
			end
		end
		
		local currentvelocity = phys:GetVelocity()
		if self.dodgeright == 1 then
			self:UApache_DodgeRight(phys)
			self.dodgeright = 0
		elseif self.dodgeleft == 1 then
			self:UApache_DodgeLeft(phys)
			self.dodgeleft = 0
		end
	self.dodgeavailable = 0
	timer.Simple(1, function() if IsValid(self) and self.dodgeavailable == 0 then self.dodgeavailable = 1 end end)
	end
end 

function ENT:UApache_IsClear(vec) -- Purpose: Initiates a quick trace check if given local vector doesn't hit world. Returns true if doesn't hit world, otherwise it gives you the world hitpos.
	-- those old times when i didn't know there is npc:VisibleVec()
	local trace = util.QuickTrace(
	self:GetPos(),
	-self:GetPos()+self:LocalToWorld(vec),
	self
	)
	if trace.HitWorld then
		return trace.HitPos
	else 
		return true
	end
end

function ENT:UApache_DodgeLeft(phys)
	self:SetVelocity(Vector(self:GetRight().x*-500,self:GetRight().y*-500,self:GetRight().z))
end	

function ENT:UApache_DodgeRight(phys)
	self:SetVelocity(Vector(self:GetRight().x*500,self:GetRight().y*500,self:GetRight().z)) -- Cscanner rolls 90 degrees when scanner's position is above than desired scan position. Applying Z force causes dumb movement when that's case. So I don't apply. 
end	

function ENT:NPC_FireProjectile_CopyFrom(proj,attachment) -- avoiding calling same calculations, copies from properties of another proj 
	local proj2=ents.Create(proj:GetClass())
	proj2:SetPos(attachment)
	proj2:SetLocalVelocity(proj:GetVelocity())
	proj2:SetAngles(proj:GetAngles())
	proj2:SetOwner(proj:GetOwner()) 
	proj2:SetLocalVelocity(proj.vel) 
	proj2:Spawn()
end 

function ENT:NPC_FireProjectile(classname,spawnpos,owner,targetvector,velocity,paeboolean) 
	-- Purpose: Quickly creates a projectile, defines position and angles and launches it towards to the enemy at given velocity.
	local projectile = ents.Create(classname)
	if isvector(spawnpos) then projectile:SetPos(spawnpos) else SafeRemoveEntity(projectile) print ("FireProjectile spawnpos doesn't refer to a vector! Killed.") return end
	if IsValid(owner) then projectile:SetOwner(owner) end
	-- AdjustAim_alien_controller(projectile, velocity)
	self:AdjustAim_uscript(projectile, velocity) -- this function calculates and sets fire angle according to proj speed and enemy speed 
	projectile:Spawn()
	return projectile
end	

function ENT:AdjustAim_uscript(proj, projspeed) -- currently we are using this script for aiming 
	local deviation = 10 -- how much your projectile will spread 
	-- gather data first 
	local enemy = proj:GetOwner():GetEnemy() 
	local selfpos = proj:GetPos() 
	local enemypos = enemy:NearestPoint(enemy:EyePos()) 
	local enemy_groundvel = enemy:GetGroundSpeedVelocity() 
	--then start processing 
	if enemypos == Vector(0,0,0) then enemypos = enemy:GetPos() + enemy:OBBMins() + enemy:OBBMaxs() end -- checks if the vector we are supplying is actually incorrect. tries some alternatives 
	if enemypos == Vector(0,0,0) then enemypos = enemy:WorldSpaceCenter() end 
	if use_deviation then 
		local clamped_lastshot = math.Clamp(proj:GetOwner().lastshot,CurTime()-20,CurTime()) 
		local a = CurTime()-clamped_lastshot 
		local b = math.random(-deviation,deviation) 
		local c = Vector(b,b,b) 
		enemypos = enemypos+(c*(a)) -- add deviation to supplied enemy position 
	end 
	-- print(enemypos, "Actual enemypos:", enemy:NearestPoint(enemy:EyePos()))
	-- Code to consider enemy's speed before shooting
	local enemyvel = vector_origin 
	if isfunction(enemy.GetVehicle) and (IsValid(enemy:GetVehicle())) then 
		if IsValid(enemy:GetVehicle():GetParent()) then 
			enemyvel = enemy:GetVehicle():GetParent():GetVelocity() *2 -- velocity of an entity parented to vehicle 
		else
			enemyvel = enemy:GetVehicle():GetPhysicsObject():GetVelocity() *2 -- velocity of vehicle 
		end
	elseif enemy_groundvel != Vector(0,0,0) then
		enemyvel = enemy_groundvel *2 -- ground velocity 
		-- print("used groundspeed:",enemyvel) 
	elseif IsValid(enemy:GetPhysicsObject()) then 
		enemyvel = enemy:GetPhysicsObject():GetVelocity() *2 -- enemy has physobj: use physobj velocity 
		-- print("used physobj:",enemyvel) 
	else
		enemyvel = enemy:GetAbsVelocity() *2 -- try what we have, as the last case 
	end
	-- Now do last calculations before taking aim
	-- proj:SetAngles((enemypos + 0.5 * enemyvel - selfpos + 0.5 * selfvel):Angle())
	local firespot = enemypos + (enemyvel * (selfpos:Distance(enemypos)/projspeed) ) 
	firespot = 0.5 * (firespot + enemypos) 
	local ang = (firespot-selfpos):Angle() 
	-- Now fire
	proj:SetAngles(ang) 
	proj:SetLocalVelocity(proj:GetForward()*projspeed) 
	proj.vel = proj:GetForward()*projspeed -- saves proj speed for NPC_FireProjectile_CopyFrom 
	-- print(proj.vel)
	-- timer.Simple(0.1, function() if IsValid(proj) then print("Actual velocity:", proj:GetVelocity()) end end)
end	

function ENT:UpdatePerpPathDistance(flMaxPathOffset) 
  if !self.bLeading and self:NPC_GetDesiredPosition() == Vector(0,0,0)  then 
        self.m_flCurrPathOffset = 0 
        return 0 
    end 

    local flNewPathOffset = self:NPC_GetDesiredPosition():Distance(self:GetPos()) 

    -- Make bomb dropping more interesting
    if self:NPC_ShouldDropBombs() then 
        local flSpeedAlongPath = self:NPC_TargetSpeedAlongPath() 

        if flSpeedAlongPath > 10 then 
            local flLeadTime = self:NPC_GetLeadingDistance() / flSpeedAlongPath 
            flLeadTime = math.Clamp(flLeadTime, 0, 2) 
            flNewPathOffset = flNewPathOffset + 0.25 * flLeadTime * self:NPC_TargetSpeedAcrossPath() 
        end

        flSpeedAlongPath = math.Clamp(flSpeedAlongPath, 100, 500) 
        local flSinHeight = SimpleSplineRemapVal(flSpeedAlongPath, 100, 500, 0, 200) 
        flNewPathOffset = flNewPathOffset + flSinHeight * math.sin(2 * math.pi * (CurTime() / 6)) 
    end 

    -- Clamp the path offset
    if flMaxPathOffset != 0 and flNewPathOffset > flMaxPathOffset then
        flNewPathOffset = flMaxPathOffset
    end

    -- Handle the maximum allowed change in the path offset
    local flMaxChange = 1000 * (-self:GetInternalVariable("m_flPrevAnimTime")) 
    if math.abs(flNewPathOffset - self.m_flCurrPathOffset) < flMaxChange then
        self.m_flCurrPathOffset = flNewPathOffset 
    else 
        local flSign = (self.m_flCurrPathOffset < flNewPathOffset) and 1 or -1 
        self.m_flCurrPathOffset = self.m_flCurrPathOffset + flSign * flMaxChange 
    end 

    return self.m_flCurrPathOffset 
end 

function ENT:NPC_TargetSpeedAlongPath() 
	if !IsValid(self:GetEnemy()) or !self.bLeading then return 0 end 
	local vecSmoothedVelocity = self:GetEnemy():GetVelocity() 
	local dir = (self:GetCurWaypointPos() - self:GetPos()):GetNormalized() 
	return vecSmoothedVelocity:Dot(dir) 
end 

function ENT:NPC_TargetSpeedAcrossPath() 
	if !IsValid(self:GetEnemy()) or !self.bLeading then return 0 end 
	local vecSmoothedVelocity = self:GetEnemy():GetVelocity() 
	return vecSmoothedVelocity:Dot(self:NPC_TargetPathAcrossDirection()) 
end 

function ENT:NPC_TargetPathAcrossDirection() 
	return self:NPC_TargetPathDirection():Cross(Vector(0,0,1)) 
end 

function ENT:NPC_GetMaxSpeedAndAccel() 
	local pAccelRate = HELICOPTER_ACCEL_RATE or 10 -- if enemy is in vehicle, *pAccelRate *= 9.0f; 
	local pMaxSpeed = HELICOPTER_SPEED 
	local target = self:NPC_GetGoalTarget() 
	if IsValid(target) then 
		pTargetSpeed = target:GetInternalVariable("speed") 
		if pTargetSpeed != 0 then 
			pMaxSpeed = pTargetSpeed 
		end 
	end 
	local moveWait = self:GetInternalVariable("m_flMoveWaitFinished") 
	if moveWait > 0 then pMaxSpeed = 0 end 
	
	return pMaxSpeed, pAccelRate 
end 

function ENT:NPC_MaxDistanceFromCurrentPath() 
	local curPath = self:NPC_GetDesiredPosition() 
	if !self.bLeading or curPath == Vector(0,0,0) then return 0 end 
	local vecTemp, t = CalcClosestPointOnLine(self:GetPos(),self.m_vecSegmentStartPoint,curPath) 
	t = math.Clamp(t,0,1) 
	local flRadius = (1.0 - t) * self:BoundingRadius() + t * self:BoundingRadius() 
	return flRadius 
end 

function ENT:NPC_ComputeNormalizedDestVelocity() 
	if self.m_nPauseState and self.m_nPauseState != PAUSE_NO_PAUSE then return Vector(0,0,0) end 
	if self:GetCurWaypointPos() == Vector(0,0,0) then return Vector(0,0,0) end 
	local vecNextTrack = self:GetNextWaypointPos() 
	if vecNextTrack == Vector(0,0,0) then vecNextTrack = self:GetCurWaypointPos() end 
	if vecNextTrack == self:GetCurWaypointPos() or self:GetCurWaypointPos() == self:GetGoalPos() then return Vector(0,0,0) end 
	local pVecVelocity = (vecNextTrack - self:GetCurWaypointPos()):GetNormalized() 
	local vecDelta = (self:GetCurWaypointPos() - self.m_vecSegmentStartPoint):GetNormalized() 
	local flDot = pVecVelocity:Dot(vecDelta) 
	pVecVelocity = pVecVelocity * math.Clamp(flDot,0,1) 
	return pVecVelocity 
end 

function ENT:NPC_ComputeActualTargetPosition(flSpeed, flTime, flPerpDist, bApplyNoise) 
	if bApplyNoise and self.m_flRandomOffsetTime <= CurTime() then 
        self.m_vecRandomOffset = VectorRand() * 25 
        self.m_flRandomOffsetTime = CurTime() + 1 
    end 

    -- If leading, has an enemy, and is on a path track, compute the point along the path 
    -- if self.bLeading and self:GetEnemy() and self:IsGoalActive() then 
        -- pDest = self:NPC_ComputePointAlongCurrentPath(flSpeed * flTime, flPerpDist) 
        -- pDest:Add(self.m_vecRandomOffset) 
        -- return pDest 
    -- end 

    -- Otherwise, compute movement towards the desired position
    local pDest = self:NPC_GetDesiredPosition() - self:GetPos() 
	
    local flDistToDesired = pDest:Length() 
    if flDistToDesired > flSpeed * flTime then 
        local scale = (flSpeed * flTime) / flDistToDesired 
        pDest:Mul(scale) 
    elseif self:IsGoalActive() then -- self:IsOnPathTrack() 
        -- Blend in a fake destination point based on the destination velocity 
        local vecDestVelocity = self:NPC_ComputeNormalizedDestVelocity() 
		-- print("ComputeNormalizedDestVelocity",vecDestVelocity) 
        vecDestVelocity:Mul(flSpeed) 

        local flBlendFactor = 1.0 - (flDistToDesired / (flSpeed * flTime)) 
        pDest:Add(vecDestVelocity * (flTime * flBlendFactor)) 
    end

    -- Add the current position to the destination 
    pDest:Add(self:GetPos()) 

    -- Add noise to the destination if needed 
    if bApplyNoise then 
        pDest:Add(self.m_vecRandomOffset) 
    end 
	return pDest 
end 

function ENT:NPC_ComputePointFromPerpDistance(vecPointOnPath, vecPathDir, flPerpDist) 
	local vecAcross = vecPathDir:Cross(Vector(0,0,1)) 
	return vecPointOnPath + (flPerpDist*vecAcross)
end 

function ENT:NPC_ComputeDistanceToLeadingPosition() 
	return self:NPC_ComputeDistanceAlongPathToPoint( self:NPC_GetGoalTarget(), self.m_pDestPathTarget, self:NPC_GetDesiredPosition(), self.m_bMovingForward )
end 

function ENT:NPC_ComputeDistanceToTargetPosition() 
	if !IsValid(self.m_pTargetNearestPath) then return end 
	local pDest = self.m_bMovingForward and self.m_pTargetNearestPath or self:NPC_GetPreviousPath(self.m_pTargetNearestPath) 
	if !IsValid(pDest) then pDest = self.m_pTargetNearestPath end 
	local bMovingForward = self:NPC_IsForwardAlongPath( self:NPC_GetGoalTarget(), pDest ) 
	local pStart = self:NPC_GetGoalTarget() 
	if bMovingForward != self.m_bMovingForward then 
		if bMovingForward then 
			local pNext = self:NPC_GetNextPath(pStart) 
			local pDest2 = self:NPC_GetNextPath(pDest) 
			if IsValid(pNext) then 
				pStart = pNext 
			end 
			if IsValid(pDest) then 
				pDest = pDest2 
			end 
		else 
			local pNext = self:NPC_GetPreviousPath(pStart) 
			local pDest2 = self:NPC_GetPreviousPath(pDest) 
			if IsValid(pNext) then 
				pStart = pNext 
			end 
			if IsValid(pDest) then 
				pDest = pDest2 
			end 
		end 
	end 
	return self:NPC_ComputeDistanceAlongPathToPoint(pStart, pDest, self.m_vecTargetPathPoint, bMovingForward) 
end 

function ENT:NPC_ComputePointAlongCurrentPath(flDistance, flPerpDist) 
    local vecPathDir = Vector() 
    local vecStartPoint = Vector() 
    
    -- Find the closest point to the current path
    self:NPC_ClosestPointToCurrentPath(vecStartPoint)
    local pTarget = vecStartPoint 
    
    if flDistance != 0 then
        local vecPrevPoint = vecStartPoint
        local pTravPath = self:NPC_GetGoalTarget()
        local pAdjustedDest = self:NPC_AdjustForMovementDirection(self:NPC_GetGoalTarget()) 

        while IsValid(pTravPath) do
            if pTravPath == pAdjustedDest then
                -- Compute direction of the path
                local vecPathDir = self:NPC_ComputePathDirection(pTravPath) 
                
                local flPathDist = pTarget:DistTo(self:NPC_GetDesiredPosition())
                if flDistance > flPathDist then
                    pTarget:Set(self:NPC_GetDesiredPosition())
                else
                    pTarget:Set(self:NPC_ComputeClosestPoint(pTarget, flDistance, self:GetDesiredPosition())) 
                end
                break
            end

            -- Compute distance from the current target to the test path point
            local flPathDist = pTarget:DistTo(pTravPath:GetPos())

            if flPathDist <= flDistance then
                flDistance = flDistance - flPathDist
                pTarget:Set(pTravPath:GetPos())

                -- Continue along the path
                pTravPath = self:NPC_GetNextPath(pTravPath)
            else
                vecPathDir = self:NPC_ComputePathDirection(pTravPath) 
                pTarget = self:NPC_ComputeClosestPoint(pTarget, flDistance, pTravPath:GetPos())
                break
            end
        end
    else
        vecPathDir = (self.m_pCurrentPathTarget:GetPos() - self.m_vecSegmentStartPoint):GetNormalized()
    end

    -- Add the perpendicular distance
    local pTarget = self:NPC_ComputePointFromPerpDistance(pTarget, vecPathDir, flPerpDist) 
	return pTarget 
end

function ENT:NPC_ComputePathDistance(pPath, pDest, bForward) 
	local flDist = 0 
	local pLast = pPath 
	local tblPath = self:NPC_GetPaths(pLast) 
	
	while IsValid(pPath) and tblPath[pPath] do 
		if !IsValid(pPath) or tblPath[pPath] == false then 
			return math.max 
		end 
		tblPath[pPath] = false 
		flDist = flDist + pLast:GetPos():Distance(pPath:GetPos()) 
		if pDest == pPath then 
			return flDist 
		end 
		pLast = pPath 
		pPath = bForward and self:NPC_GetNextPath(pPath) or self:NPC_GetPreviousPath(pPath) 
	end 
end 

function ENT:NPC_IsForwardAlongPath(pPath, pPathTest) 
	local flForwardDist = self:NPC_ComputePathDistance(pPath, pPathTest, true) 
	local flReverseDist = self:NPC_ComputePathDistance(pPath, pPathTest, false) 
	if flForwardDist == math.max and flReverseDist == math.max then return end 
	return flForwardDist <= flReverseDist 
end 

function ENT:NPC_Flight(flInterval) 
	self:SetSaveValue("m_bIsMoving",true) 
	-- If on ground, set no ground entity
    if self:IsFlagSet(FL_ONGROUND) then self:SetGroundEntity(NULL) self:RemoveFlags(FL_ONGROUND) end 
    -- Determine the distances we must lie from the path
    local flMaxPathOffset = self:NPC_MaxDistanceFromCurrentPath()  -- self:MaxDistanceFromCurrentPath() 
	-- print("flMaxPathOffset:",flMaxPathOffset) 
    local flPerpDist = self:UpdatePerpPathDistance(flMaxPathOffset) 
	-- print("flPerpDist and flMaxPathOffset:",flPerpDist, flMaxPathOffset) 

    local flMinDistFromSegment, flMaxDistFromSegment

    if !self.bLeading then
        flMinDistFromSegment = 0
        flMaxDistFromSegment = 0
    else
        flMinDistFromSegment = math.abs(flPerpDist) + 100
        flMaxDistFromSegment = math.abs(flPerpDist) + 200

        if flMaxPathOffset != 0 then
            if flMaxDistFromSegment > flMaxPathOffset - 100 then
                flMaxDistFromSegment = flMaxPathOffset - 100
            end
            if flMinDistFromSegment > flMaxPathOffset - 200 then
                flMinDistFromSegment = flMaxPathOffset - 200
            end
        end
    end

    -- Get maximum speed and acceleration
    local maxSpeed, accelRate = self:NPC_GetMaxSpeedAndAccel() 

    -- Get current velocity and compute distance
    local flCurrentSpeed = self:GetVelocity():Length() 
    local flDist = math.min(flCurrentSpeed + accelRate, maxSpeed) 
    local flTime = 1 -- estimate where it'll be in a second 
	
	local vecTargetPosition = self:NPC_ComputeActualTargetPosition(flDist, flTime, flPerpDist) 
	debugoverlay.Line(self:GetPos(),vecTargetPosition) 

    -- Raise high in the air when doing the shooting attack
    local flAdditionalHeight = 0
    if self.m_nAttackMode and self.m_nAttackMode == ATTACK_MODE_BULLRUSH_VEHICLE then 
        flAdditionalHeight = math.Clamp(self.m_flBullrushAdditionalHeight, 0, flMaxPathOffset) 
        vecTargetPosition.z = vecTargetPosition.z + flAdditionalHeight 
    end

    -- Update facing direction and compute velocity
    self:UpdateFacingDirection(vecTargetPosition) 
    local accel = self:NPC_ComputeVelocity(vecTargetPosition, flAdditionalHeight, flMinDistFromSegment, flMaxDistFromSegment, flInterval) 
	self:SetVelocity(accel) 
    local angVel = self:ComputeAngularVelocity(accel, self.m_vecDesiredFaceDir, flInterval) 
	self:UpdateDesiredPosition() 
end 

-- scanner functions 
function ENT:OverrideMove(flInterval) 
    self:NPC_Flight(flInterval) 
	-- debugoverlay.Line(self:GetPos(),Entity(2):NPC_BestPointOnPath(Entity(78),Entity(1):GetPos(),10,true,false):GetPos()) -- get nearest pos to target 
	return true 
end 

function ENT:NPC_GetPaths(pathTrack, visited) 
    -- Create the table to hold visited path_tracks if not provided 
    if !visited then 
        visited = {} 
    end 

    -- If this pathTrack has already been visited, stop recursion 
    if visited[pathTrack] then 
        return visited 
    end 

    -- Mark the current pathTrack as visited 
    visited[pathTrack] = true 

    -- Get the next path_track entity using the "target" keyvalue 
    local nextTarget = pathTrack:GetKeyValues()["target"] 
    if #nextTarget > 0 then 
        -- Find the next path_track entity by name 
        local nextPathTrack = ents.FindByName(nextTarget) 
        if nextPathTrack and !table.IsEmpty(nextPathTrack) then 
            -- Recursively call the function for the next path_track 
            for _, track in ipairs(nextPathTrack) do 
                self:NPC_GetPaths(track, visited) 
            end 
        end 
    end 

    return visited 
end 

function ENT:NPC_GetGoalTarget() 
	local m_hGoalEnt = self:GetInternalVariable("m_hGoalEnt") 
	return IsValid(self:GetGoalTarget()) and self:GetGoalTarget() or IsValid(m_hGoalEnt) and m_hGoalEnt or NULL 
end 

function ENT:NPC_GetNextPath(pathTrack) 
	pathTrack = IsValid(pathTrack) and pathTrack or self:NPC_GetGoalTarget() 
	local nextTarget = pathTrack:GetKeyValues()["target"] 
	 if #nextTarget > 0 then 
        -- Find the next path_track entity by name 
        local nextPathTrack = ents.FindByName(nextTarget) 
        if nextPathTrack and !table.IsEmpty(nextPathTrack) then 
			return nextPathTrack[1] 
		end 
	end 
	return NULL 
end 

function ENT:NPC_GetPreviousPath(pathTrack) 
	pathTrack = IsValid(pathTrack) and pathTrack or self:NPC_GetGoalTarget() 
	for k,v in pairs(ents.FindByClass(pathTrack:GetClass())) do 
		local theirTarget = v:GetKeyValues()["target"] 
		if theirTarget == pathTrack:GetName() then return v end 
	end 
	return NULL 
end 

function ENT:NPC_BestPointOnPath(pPath, targetPos, flAvoidRadius, visible, bFarthestPoint)
	if !IsValid(pPath) then pPath = self:NPC_GetGoalTarget() end
	if !flAvoidRadius then flAvoidRadius = 0 end

	if !IsValid(pPath) then return NULL end
	local pVehicle = NULL
	local pTargetEnt = self:GetTrackPatherTargetEnt()
	if IsValid(pTargetEnt) and IsValid(pTargetEnt:GetParent()) then
		pVehicle = pTargetEnt:GetParent()
	end
	flAvoidRadius = flAvoidRadius * flAvoidRadius

	local flNearestDist = bFarthestPoint and 0 or math.huge  -- Use `math.huge` for max distance
	local flFarthestDistSqr = (self.m_flFarthestPathDist - 2 * self.m_flTargetDistanceThreshold) 
	flFarthestDistSqr = flFarthestDistSqr * flFarthestDistSqr

	local pNearestPath = NULL

	for k, v in pairs(self:NPC_GetPaths(pPath)) do
		local flPathDist = (k:GetPos() - targetPos):LengthSqr() 

		-- Update logic for finding the nearest point
		if bFarthestPoint then
			if flPathDist <= flNearestDist and flNearestDist <= flFarthestDistSqr then
				continue
			elseif flPathDist >= flNearestDist then
				continue
			end
		else
			if flPathDist >= flNearestDist then
				continue
			end
		end

		local inAvoidRadius = flAvoidRadius and (k:GetPos() - targetPos):Length2DSqr() <= flAvoidRadius
		if inAvoidRadius then
			continue
		end

		if visible then
			local pBlocker = util.QuickTrace(k:GetPos(), -(k:GetPos() - targetPos), self).Entity
			local bHitTarget = IsValid(pTargetEnt) and (pTargetEnt == pBlocker) or IsValid(pVehicle) and pVehicle == pBlocker
			if IsValid(pBlocker) and !bHitTarget or self.m_bForcedMove then
				continue
			end
		end

		-- Update nearest path only if it's closer
		pNearestPath = k
		flNearestDist = flPathDist
	end

	return pNearestPath, flNearestDist
end 

function ENT:NPC_ComputeClosestPoint(vecStart, flMaxDist, vecTarget) 
	local vecDelta = vecTarget - vecStart 
	local flDistSqr = vecDelta:LengthSqr() 
	if flDistSqr <= flMaxDist * flMaxDist then return vecTarget else vecDelta = vecDelta / math.sqrt(flDistSqr) return vecStart + flMaxDist * vecDelta end 
end 

function ENT:NPC_ComputeLeadingPointAlongPath(vecStartPoint, pFirstTrack, flDistance)
    local bMovingForward = flDistance > 0
    flDistance = math.abs(flDistance)

    local pTravPath = pFirstTrack
    local pPrev = self:NPC_GetPreviousPath(pFirstTrack)
    
    -- If we're moving backwards and there's a previous path, start with that one
    if !bMovingForward and IsValid(pPrev) then
        pTravPath = pPrev
    end

    -- Initialize the target point as the starting point
    local pTarget = vecStartPoint
    local pNextPath = NULL

    -- Loop through the path nodes
    while IsValid(pTravPath) do
        -- Get the next path based on the direction of movement
        pNextPath = bMovingForward and self:NPC_GetNextPath(pTravPath) or self:NPC_GetPreviousPath(pTravPath)

        -- Calculate the distance between the current target and the next path node
        local flPathDist = pTarget:DistTo(pTravPath:GetPos())

        -- If the distance to the current node is less than or equal to the remaining distance
        if flPathDist <= flDistance then
            -- Subtract this distance from the total
            flDistance = flDistance - flPathDist
            
            -- Move the target point to the current node
            pTarget = pTravPath:GetPos()

            -- If there's no valid next path, return the current path node
            if !IsValid(pNextPath) then 
                return bMovingForward and pTravPath or self:NPC_GetNextPath(pTravPath)
            end
        else
            -- If the current node is further than the remaining distance, compute the closest point
            pTarget = self:NPC_ComputeClosestPoint(pTarget, flDistance, pTravPath:GetPos())
            return bMovingForward and pTravPath or self:NPC_GetNextPath(pTravPath)
        end

        -- Move to the next path in the sequence
        pTravPath = pNextPath
    end

    return NULL
end 

function ENT:NPC_ComputeDistanceAlongPathToPoint(pStartTrack, pDestTrack, vecDestPosition, bMovingForward)
    local flTotalDist = 0 
    
    -- Get the closest point to the current path
    local vecPoint = self:NPC_ClosestPointToCurrentPath() 

    local pTravPath = pStartTrack
    local pNextPath = NULL
    local pTestPath = NULL
	
	local tblPath = self:NPC_GetPaths(pTravPath) 
	while IsValid(pTravPath) and tblPath[pTravPath] do 
		tblPath[pTravPath] = false 
		pNextPath = bMovingForward and self:NPC_GetNextPath(pTestPath) or self:NPC_GetPreviousPath(pTestPath) 
		pTestPath = pTravPath 
		if pTestPath == pDestTrack then 
			local vecDelta = vecDestPosition - vecPoint
            local vecPathDelta = self:NPC_ComputePathDirection(pTestPath) 

            -- Calculate dot product to determine the direction and distance
            local flDot = vecDelta:Dot(vecPathDelta)
            flTotalDist = flTotalDist + (flDot > 0 and 1 or -1) * vecDelta:Length2D()
            break
		end 
		 -- Calculate the 2D distance between the current point and the test path's position
        flTotalDist = flTotalDist + (bMovingForward and 1 or -1) * vecPoint:Distance(pTestPath:GetPos())
        vecPoint = pTestPath:GetPos() 
	end 

    return flTotalDist
end 

function ENT:NPC_IsOnSameTrack(pPath1, pPath2) 
	if !IsValid(pPath1) or !IsValid(pPath2) then return false end 
	for k,v in pairs(self:NPC_GetPaths(pPath1)) do 
		if k == pPath2 then return true end 
	end 
	return false 
end 

function ENT:NPC_FindClosestPointOnPath(pPath, targetPos) 
    -- If a path is not provided, use the destination path target
    pPath = IsValid(pPath) and pPath or self:NPC_GetGoalTarget() 
	if !IsValid(pPath) then return NULL end 

    -- Initialize nearest path and distances
    local pNearestPath = NULL
    local flNearestDist2D = 999999999
    local flNearestDist = 999999999
    local flPathDist, flPathDist2D = 0,0 

    local vecNearestPoint = Vector(0, 0, 0)
    local vecNearestPathSegment = Vector(0, 0, 0)

    -- Iterate twice (once for previous paths and once for next paths)
    for i = 0, 1 do
        local pTravPath = pPath 
        local pNextPath = NULL 

        -- Iterate through paths using self:NPC_GetPaths
        for k, _ in pairs(self:NPC_GetPaths(pTravPath)) do
            pNextPath = (i == 0) and self:NPC_GetPreviousPath(pTravPath) or self:NPC_GetNextPath(pTravPath)

            -- Circular loop check: If the path has been visited, break the loop
            -- if self:NPC_HasBeenVisited(pTravPath) then
                -- break
            -- end
            -- Mark the current path as visited
            -- self:NPC_VisitPath(pTravPath)

            -- Skip alternative paths in leading behavior
            if pTravPath:GetInternalVariable("m_paltpath") then
                print(self,": Alternative paths in path_track not allowed when using the leading behavior!") 
            end

            -- Make sure there's a valid next path for line segment calculation
            if !IsValid(pNextPath) then break end

            -- Calculate the closest point on the line segment between current and next path
            local vecClosest = CalcClosestPointOnLineSegment(targetPos, pTravPath:GetPos(), pNextPath:GetPos())

            -- Calculate the 2D distance to the target position
            flPathDist2D = vecClosest:DistToSqr(targetPos)

            -- Update the nearest path if the current one is closer
            if flPathDist2D <= flNearestDist2D then
                flPathDist = (vecClosest.z - targetPos.z) ^ 2 + flPathDist2D
                if flPathDist2D < flNearestDist2D or flPathDist < flNearestDist then
                    pNearestPath = (i == 0) and pTravPath or pNextPath
                    flNearestDist2D = flPathDist2D
                    flNearestDist = flPathDist
                    vecNearestPoint = vecClosest
                    vecNearestPathSegment = pNextPath:GetPos() - pTravPath:GetPos()
                    if i == 0 then
                        vecNearestPathSegment = vecNearestPathSegment * -1
                    end
                end
            end
        end
    end

    -- Normalize the nearest path segment direction
    vecNearestPathSegment = vecNearestPathSegment:GetNormalized() 

    -- Calculate the perpendicular distance from the path
    local pDistanceFromPath = self:NPC_ComputePerpDistanceFromPath(vecNearestPoint, vecNearestPathSegment, targetPos)

    -- Assign the closest point and path direction to the output parameters
    local pVecClosestPoint = vecNearestPoint 

    return pNearestPath, pVecClosestPoint, vecNearestPathSegment, pDistanceFromPath 
end 

function ENT:NPC_ComputePerpDistanceFromPath(vecPointOnPath, vecPathDir, vecPointOffPath) 
    -- Create a vector that is perpendicular to the path direction (cross product with the Z-axis) 
    local vecAcross = vecPathDir:Cross(Vector(0, 0, 1)) 

    -- Calculate the vector from the point on the path to the point off the path 
    local vecDelta = vecPointOffPath - vecPointOnPath 

    -- Project vecDelta onto the perpendicular direction 
    vecDelta = vecDelta - vecPathDir * vecPathDir:Dot(vecDelta) 

    -- Calculate the 2D distance (ignoring Z) from the path 
    local flDistanceFromPath = vecDelta:Length2D() 

    -- If the point is on the left side, make the distance negative 
    if vecAcross:Dot(vecDelta) < 0 then flDistanceFromPath = flDistanceFromPath * -1 end 

    return flDistanceFromPath 
end 

function ENT:NPC_ComputePathDirection(pPath) 
	local pVecPathDir = Vector(0,0,0) 
	local prevPath, nextPath = self:NPC_GetPreviousPath(pPath), self:NPC_GetNextPath(pPath) 
	if IsValid(prevPath) then 
		pVecPathDir = pPath:GetPos() - prevPath:GetPos() 
	elseif IsValid(nextPath) then 
		pVecPathDir = nextPath:GetPos() - pPath:GetPos() 
	else 
		return Vector(1,0,0) 
	end 
	return pVecPathDir:GetNormalized() 
end 

function ENT:NPC_SetupNewCurrentTarget(pTrack) 
	if !IsValid(pTrack) then return end 
	self.m_vecSegmentStartPoint = self:EyePos() 
	self.m_vecSegmentStartSplinePoint = self.m_vecSegmentStartPoint + (self:GetAbsVelocity() * -2) 
	self:SetSaveValue("m_hGoalEnt",pTrack) 
	self:NPC_SetDesiredPosition(pTrack:GetPos()) 
end 

function ENT:NPC_MoveToTrackPoint(pTrack) 
	if !IsValid(pTrack) then return false end 
	if self:NPC_IsOnSameTrack(pTrack, self:NPC_GetGoalTarget()) then 
		self.m_pDestPathTarget = pTrack 
		self.m_bMovingForward = self:NPC_IsForwardAlongPath(self:NPC_GetGoalTarget(), pTrack) 
		self.m_bForcedMove = true 
		return true 
	else 
		local pClosestTrack = self:NPC_BestPointOnPath( pTrack, self:WorldSpaceCenter(), 0, false, false) 
		if !IsValid(pClosestTrack) then return false end 
		self:NPC_SetupNewCurrentTarget(pClosestTrack) 
		self.m_pDestPathTarget = pClosestTrack 
		self:SetSaveValue("m_hGoalEnt",pClosestTrack) 
		self.m_bMovingForward = true 
		return true 
	end 
end 

function ENT:NPC_MoveToClosestTrackPoint(pTrack) 
	if self:NPC_IsOnSameTrack(pTrack, self:NPC_GetGoalTarget()) then return false end 
	local pClosestTrack = self:NPC_BestPointOnPath( pTrack, self:WorldSpaceCenter(), 0, false, false) 
	if !IsValid(pClosestTrack) then return false end 
	self:NPC_SetupNewCurrentTarget(pClosestTrack) 
	self.m_pDestPathTarget = pClosestTrack 
	self:SetSaveValue("m_hGoalEnt",pClosestTrack) 
	self.m_bMovingForward = true 
	if self.m_bLeading then 
		self.m_bForcedMove = true 
	end 
end 

function ENT:NPC_ClosestPointToCurrentPath() 
	-- self.m_vecSegmentStartPoint = self:NPC_GetDesiredPosition() 
	if self:GetCurWaypointPos() == Vector(0,0,0) then return Vector(0,0,0) end 
	-- local vClosest, t = CalcClosestPointOnLine(self:GetPos(), self.m_vecSegmentStartPoint, self:GetCurWaypointPos()) 
	local vClosest, t = CalcClosestPointOnLine(self:GetPos(), self.m_vecSegmentStartPoint, self:NPC_GetDesiredPosition()) 
	return vClosest, t 
end 

local function CalcClosestPointOnLineSegment( P, vLineA, vLineB ) 
	local t, vDir = CalcClosestPointToLineT(P, vLineA, vLineB) 
	t = math.Clamp(t,0,1) 
	local vClosest = vLineA + vDir * t -- Closest point on the line 
	return vClosest, t 
end 

function ENT:ApplySidewaysDrag(vecRight) 
	local vecNewVelocity = self:GetAbsVelocity() 
	vecNewVelocity.x = vecNewVelocity.x * 1.0 - math.abs( vecRight.x ) * 0.05 
	vecNewVelocity.y = vecNewVelocity.y * 1.0 - math.abs( vecRight.y ) * 0.05 
	vecNewVelocity.z = vecNewVelocity.z * 1.0 - math.abs( vecRight.z ) * 0.05 
	self:SetLocalVelocity( vecNewVelocity ) 
end 

function ENT:ApplyGeneralDrag() 
	local vecNewVelocity = self:GetAbsVelocity() 
	vecNewVelocity = vecNewVelocity * 0.995 
	self:SetLocalVelocity( vecNewVelocity ) 
end 

local skiptasks = { [62] = true, [63] = true, [64] = true, [66] = true, [67] = true, [69] = true, [70] = true, [71] = true, [72] = true, [120] = true } 

function ENT:StartEngineTask(taskid,data,cFromLua) 
	self.iCurEngineTask = taskid 
	local condlist = { COND.HEAR_DANGER } -- value must be the condition number 
	-- for i = 1, table.Count(COND) do // add all conditions to ignore list 
		-- condlist[i] = i 
	-- end 
	
	self:SetIgnoreConditions(condlist,#condlist) -- ignore all conditions 
	-- skip turn tasks 
	if skiptasks[taskid] then self:TaskComplete() return true end 
	-- if taskid == 69 or taskid == 66 or taskid == 67 or taskid == 62 or taskid == 64 or taskid == 70 or taskid == 71 or taskid == 72 or taskid == 63 or taskid == 120 then 
		-- self:TaskComplete() 
		-- return true 
	-- end 
	if taskid == ai.GetTaskID("TASK_RANGE_ATTACK1") then 
		-- self:Innate_Range_Attack1() 
	elseif taskid ==  ai.GetTaskID("TASK_RANGE_ATTACK2") then 
		self:Innate_Range_Attack2() 
	elseif taskid == ai.GetTaskID("TASK_GET_CHASE_PATH_TO_ENEMY") then 
		-- self:ChainStartTask(taskid,taskdata) 
	elseif taskid == ai.GetTaskID("TASK_FIND_COVER_FROM_ENEMY") then 
		-- local taskStatus, taskFail = self:ChainStartTask("TASK_GET_CHASE_PATH_TO_ENEMY") 
		-- if !taskFail then self:TaskComplete() else self:SetCondition(35) end 
		-- print(taskFail) 
		-- print("before NavSetGoalPos") 
		-- print(self:NavSetWanderGoal( 2700, 2700 )) 
		self:NavSetWanderGoal( 2700, self:BoundingRadius()*5 ) 
		-- print("after navsetgoalpos") 
		self:TaskComplete() 
		return true 
		-- local taskStatus, taskFail 
		-- if data == 0 then taskStatus, taskFail = self:ChainStartTask(taskid,data + 1) end 
		-- if data != 0 then return true end 
		-- if taskFail then 
			-- taskStatus, taskFail = self:ChainStartTask("TASK_GET_CHASE_PATH_TO_ENEMY") 
			-- print("called getchasepath", taskFail) 
			-- if !taskFail then 
				-- self:TaskComplete() 
				-- self:ClearCondition(35) 
				-- return true 
			-- end 
		-- end 
	end 
	if self:GetCurrentSchedule() == SCHED_DROPSHIP_DUSTOFF and taskid == ai.GetTaskID("TASK_WALK_PATH") then 
		local m_vecCommandGoal = self:GetInternalVariable("m_vecCommandGoal") 
		if m_vecCommandGoal == vector_origin and IsValid(self:GetEnemy()) then 
			local lpos = self:GetEnemyLastKnownPos() 
			lpos = self:UFighter_MoveLimit(lpos) 
			self:SetSaveValue("m_vecCommandGoal",lpos) 
		end 
		self:ChainStartTask(ai.GetTaskID("TASK_GET_PATH_TO_COMMAND_GOAL")) 
		self:SetSaveValue("m_vecCommandGoal",vector_origin) 
		if self:GetCurWaypointPos() == vector_origin then self:TaskFail("really no way") end 
	end 
	
	if taskid == ai.GetTaskID("TASK_GET_PATH_TO_RANGE_ENEMY_LKP_LOS") and data == 0 then 
		-- prevent npcs from lining up behind each other, look for different strategies 
		if self.NPC_Should_Flank and self:NPC_Should_Flank() then 
			self:NPC_Begin_Flank() -- hunter's get flank path task 
			self:StartEngineTask(26,self.randFlankAng or 0) -- actual flank task 
			-- self:SetTaskStatus(TASKSTATUS_COMPLETE) 
			-- self:TaskComplete() 
			return true 
		elseif !IsValid(self:GetActiveWeapon()) then 
			self:StartEngineTask(ai.GetTaskID("TASK_GET_PATH_TO_RANGE_ENEMY_LKP_LOS"),784) 
			-- self:SetTaskStatus(TASKSTATUS_COMPLETE) 
			-- self:TaskComplete() 
			return true -- move towards enemy 
		end 
	end 
	-- if taskid == 48 then self:ResetIdealActivity(ACT_IDLE) self:SetIdealActivity(ACT_IDLE) self:SetMovementActivity(ACT_IDLE) return true end 
	-- if taskid == 49 then self:ResetIdealActivity(ACT_IDLE) self:SetIdealActivity(ACT_IDLE) self:SetMovementActivity(ACT_IDLE) return true end 
	-- if taskid == 129 then self:ResetIdealActivity(ACT_IDLE) self:SetIdealActivity(ACT_IDLE) self:SetMovementActivity(ACT_IDLE) return true end 
end 

function ENT:RunEngineTask(taskid,data,cFromLua) 
	if taskid == ai.GetTaskID("TASK_RANGE_ATTACK1") then 
		self:TaskComplete() 
		self:Innate_Range_Attack1() 
		return true 
	end 
end 

function ENT:Innate_Range_Attack1() 
	local rocket1attachment = self:GetAttachment(1) 
	local rocket2attachment = self:GetAttachment(2) 
		
	local proj1 = ents.Create("uatracer") 
	proj1:SetPos(rocket1attachment.Pos) 
	proj1:SetAngles(self:GetAimVector():Angle()) 
	proj1:SetOwner(self) 
	proj1:Spawn() 
		
	local proj2 = ents.Create("uatracer") 
	proj2:SetPos(rocket2attachment.Pos) 
	proj2:SetAngles(self:GetAimVector():Angle()) 
	proj2:SetOwner(self) 
	proj2:Spawn() 
end 

--[[ 
function ENT:NPC_ComputeVelocity(vecTargetPosition, flAdditionalHeight, flMinDistFromSegment, flMaxDistFromSegment) 
	local vecAdj = Angle( 5.0, 0, 0 ) 
	local localAngles = self:GetLocalAngles() 
	local angVel = self:GetLocalAngularVelocity() 
	local maxSpeed, accelRate = self:NPC_GetMaxSpeedAndAccel() 

	-- Compute the adjusted angles
	local adjustedAngles = localAngles + angVel * 2 + vecAdj 

	-- Calculate forward, right, and up vectors from the adjusted angles 
	local forward = adjustedAngles:Forward() 
	local right = adjustedAngles:Right() 
	local up = adjustedAngles:Up() 
	local flSide = self.m_vecDesiredFaceDir:Dot(right) 
	
	if flSide < 0 then 
		if angVel.y < 60 then 
			angVel.y = angVel.y + 8 
		end 
	else 
		if angVel.y > -60 then 
			angVel.y = angVel.y - 8 
		end 
	end 
	angVel.y = angVel.y * ( 0.98 ) 
	
	-- estimate where I'll be in two seconds
	up = (localAngles + angVel * 1 + vecAdj):Up() 
	local vecEst = self:GetPos() + self:GetAbsVelocity() * 2.0 + up * self.m_flForce * 20 - Vector( 0, 0, 384 * 2 ) 
	
	adjustedAngles = self:GetLocalAngles() + vecAdj 
	local forward = adjustedAngles:Forward() 
	local right = adjustedAngles:Right() 
	local up = adjustedAngles:Up() 
	
	local vecImpulse = Vector(0,0,0) 
	vecImpulse.x = up.x * self.m_flForce 
	vecImpulse.y = up.y * self.m_flForce 
	vecImpulse.z = up.z * self.m_flForce 
	vecImpulse.z = vecImpulse.z - 38.4 
	-- self:SetAbsVelocity(vecImpulse) 
	local flSpeed = self:GetAbsVelocity():Length() 
	local flDir = Vector( forward.x, forward.y, 0 ):Dot(Vector( self:GetAbsVelocity().x, self:GetAbsVelocity().y, 0 ) ) 
	if (flDir < 0 ) then flSpeed = -flSpeed end 
	local flDist = (self:NPC_GetDesiredPosition() - vecEst):Dot(forward) 
	local flSlip = -((self:NPC_GetDesiredPosition() - vecEst):Dot(right)) 
	
	if flSlip > 0 then
		if self:GetLocalAngles().r > -30 and angVel.z > -15 then
			angVel.z = angVel.z - 4
		else
			angVel.z = angVel.z + 2
		end
	else
		if self:GetLocalAngles().r < 30 and angVel.z < 15 then
			angVel.z = angVel.z + 4
		else
			angVel.z = angVel.z - 2
		end
	end 
	self:ApplySidewaysDrag( right ) 
	self:ApplyGeneralDrag() 
	
	local MAX_FORCE = 80	
	local FORCE_POSDELTA = 12	
	local FORCE_NEGDELTA = 8 
	
	if self.m_flForce < MAX_FORCE and vecEst.z < self:NPC_GetDesiredPosition().z then 
		self.m_flForce = self.m_flForce + FORCE_POSDELTA 
	elseif self.m_flForce > 30 then 
		if (vecEst.z > self:NPC_GetDesiredPosition().z) then 
			self.m_flForce = self.m_flForce - FORCE_NEGDELTA 
		end 
	end 
	
	-- pitch forward or back to get to target
	-- -----------------------------------------
	-- Pitch is reversed since Half-Life! (sjb)
	-- -----------------------------------------
	if flDist > 0 and flSpeed < maxSpeed and self:GetLocalAngles().x + angVel.x < 40 then 
		-- lean forward
		angVel.x = angVel.x + 12.0 
		
	elseif (flDist < 0 && flSpeed > -50 && self:GetLocalAngles().x + angVel.x  > -20) then 
		-- lean backward
		angVel.x = angVel.x - 12.0 
	elseif (self:GetLocalAngles().x + angVel.x < 0) then 
		angVel.x = angVel.x + 4.0 
	elseif (self:GetLocalAngles().x + angVel.x > 0) then 
		angVel.x = angVel.x - 4.0 
	end 
	
	return vecImpulse 
	-- self:SetLocalAngularVelocity( angVel ) 
end 
--]] 

-- HELICOPTER_DT is replaced with flInterval which returns last time a movement is performed 
function ENT:NPC_ComputeVelocity(vecTargetPosition, flAdditionalHeight, flMinDistFromSegment, flMaxDistFromSegment, flInterval) 
	local deltaPos, pVecAccel = (vecTargetPosition - self:GetPos()), Vector(0,0,0)  
	pVecAccel = 2 * (deltaPos - self:GetAbsVelocity()) 
	pVecAccel.z = pVecAccel.z + HELICOPTER_GRAVITY -- HELICOPTER_GRAVITY 
	local flDistFromPath = 0 
	local vecPoint, vecDelta = Vector(0,0,0), Vector(0,0,0) 
	
	if flMaxDistFromSegment != 0 then 
		vecPoint, t = self:NPC_ClosestPointToCurrentPath( ) 
		print("vecPoint:",vecPoint) 
		-- debugoverlay.Line(self:GetPos(),vecPoint,0.3) 
		if flAdditionalHeight != 0 then 
			local vecEndPoint, vecClosest = Vector(0,0,0), Vector(0,0,0) 
			vecEndPoint = vecPoint 
			vecEndPoint.z = vecEndPoint.z + flAdditionalHeight 
			vecPoint = CalcClosestPointOnLineSegment( self:GetPos(), vecPoint, vecEndPoint ) 
		end 
		
		vecDelta = vecPoint - self:GetPos() 
		flDistFromPath = vecDelta:Length() 
		vecDelta = vecDelta:GetNormalized() 
		if flDistFromPath > flMaxDistFromSegment then 
			local flAmount = (flDistFromPath - flMaxDistFromSegment) / 200 
			flAmount = math.Clamp( flAmount, 0, 1 ) 
			pVecAccel = pVecAccel + (flAmount * 200.0) * vecDelta -- VectorMA( *pVecAccel, flAmount * 200.0f, vecDelta, *pVecAccel ) 
			
		end 
		
	end 
	
	local vecAvoidForce = self:NPC_ComputeAvoidanceSpheres(350,2) 
	print("vecAvoidForce",vecAvoidForce) 
	pVecAccel = pVecAccel + vecAvoidForce 
	-- vecAvoidForce = self:NPC_ComputeAvoidanceBoxes(350,2) 
	-- pVecAccel = pVecAccel + vecAvoidForce 
	-- if ( !HasSpawnFlags( SF_HELICOPTER_IGNORE_AVOID_FORCES ) )
	-- {
		-- Vector vecAvoidForce;
		-- CAvoidSphere::ComputeAvoidanceForces( this, 350.0f, 2.0f, &vecAvoidForce );
		-- *pVecAccel += vecAvoidForce;
		-- CAvoidBox::ComputeAvoidanceForces( this, 350.0f, 2.0f, &vecAvoidForce );
		-- *pVecAccel += vecAvoidForce;
	-- }
	pVecAccel.z = math.Clamp( pVecAccel.z, HELICOPTER_GRAVITY * 0.2, HELICOPTER_GRAVITY * 2.0 ) 
	local flHorizLiftFactor = math.abs( pVecAccel.x ) * 0.10 + math.abs( pVecAccel.y ) * 0.10 
	local flNewHorizLiftFactor = math.Clamp( deltaPos.z, HELICOPTER_MAX_DZ_DAMP, HELICOPTER_MIN_DZ_DAMP ) 
	flNewHorizLiftFactor = SimpleSplineRemapVal( flNewHorizLiftFactor, HELICOPTER_MIN_DZ_DAMP, HELICOPTER_MAX_DZ_DAMP, flHorizLiftFactor, 2.5 * (HELICOPTER_GRAVITY * 0.2) ) 
	local flDampening = (flNewHorizLiftFactor != 0) and (flNewHorizLiftFactor / flHorizLiftFactor) or 1.0 
	
	if flDampening < 1 then 
		pVecAccel.x = pVecAccel.x * flDampening 
		pVecAccel.y = pVecAccel.y * flDampening 
		flHorizLiftFactor = flNewHorizLiftFactor 
	end 
	local forward, right, up = self:GetForward(), self:GetRight(), self:GetUp() 
	
	local flForceBlend = IsValid(self:NPC_GetEnemyVehicle()) and HELICOPTER_FORCE_BLEND_VEHICLE or HELICOPTER_FORCE_BLEND 
	-- First, attenuate the current force 
	self.m_flForce = self.m_flForce * flForceBlend 
	
	-- Now add force based on our acceleration factors 
	self.m_flForce = self.m_flForce + (( pVecAccel.z + flHorizLiftFactor ) * flInterval * (1 - flForceBlend)) 
	
	-- The force is always *locally* upward based; we pitch + roll the chopper to get movement 
	local vecImpulse = up * self.m_flForce 
	
	-- NOTE: These have to be done *before* the additional path distance drag forces are applied below
	self:ApplySidewaysDrag( right ) 
	self:ApplyGeneralDrag() 
	if self:GetInternalVariable("m_lifeState") != 1 or (self:GetInternalVariable("m_lifeState") == 1 and IsValid(self:GetCrashPoint())) then 
        vecImpulse.z = vecImpulse.z - HELICOPTER_GRAVITY * flInterval 
        if flMinDistFromSegment != 0 and (flDistFromPath > flMinDistFromSegment) then 
            local vecVelDir = self:GetAbsVelocity()
            
            -- Dot product between impulse and direction vector
			-- vecDelta = Vector(0,50,0) 
            local flDot = vecImpulse:Dot(vecDelta)
            if flDot < 0 then
                vecImpulse = vecImpulse + (-flDot * 0.1) * vecDelta
            end
            
            -- Adjust for current velocity along path direction
            flDot = vecVelDir:Dot(vecDelta)
			
            if flDot < 0 then
                vecImpulse = vecImpulse + (-flDot * 0.1) * vecDelta
            end
        end
    else
		vecImpulse.z = vecImpulse.z -HELICOPTER_GRAVITY * flInterval 
	end 
	
	vecImpulse.x = vecImpulse.x + pVecAccel.x * flInterval 
	vecImpulse.y = vecImpulse.y + pVecAccel.y * flInterval 
	vecImpulse.x = vecImpulse.x * 0.1 
	vecImpulse.y = vecImpulse.y * 0.1 
	return vecImpulse 
end 

-- vecImpulse.x = vecImpulse.x + pVecAccel.x * flInterval 
-- vecImpulse.y = vecImpulse.y + pVecAccel.y * flInterval 

function ENT:ComputeAngularVelocity( vecGoalUp, vecFacingDirection, flInterval ) 
	local goalAngAccel = Angle() 
	local m_lifeState = self:GetInternalVariable("m_lifeState") 
	if m_lifeState != 1 or (m_lifeState == 1 and IsValid(self:GetCrashPoint())) then 
		local forward, right, up = self:GetForward(), self:GetRight(), self:GetUp() 
		local goalUp = vecGoalUp:GetNormalized() 
		
		local goalPitch = math.deg(math.asin(forward:Dot(goalUp))) 
		local goalYaw = math.deg(math.atan2(vecFacingDirection.y, vecFacingDirection.x)) 
		local goalRoll = math.deg(math.asin(right:Dot(goalUp)) + self.m_flGoalRollDmg) 
		
		goalPitch = goalPitch * 0.75 
		-- clamp goal orientations 
		goalPitch = math.Clamp( goalPitch, -30, 45 ) 
		goalRoll = math.Clamp( goalRoll, -45, 45 ) 
		
		local dt = 0.6 

		-- Calculate angular acceleration needed to hit goal pitch in dt time 
		goalAngAccel.x = 2.0 * (math.AngleDifference(goalPitch, math.NormalizeAngle(self:GetAngles().x)) - self:GetLocalAngularVelocity().x * dt) / (dt * dt) 
		goalAngAccel.y = 2.0 * (math.AngleDifference(goalYaw, math.NormalizeAngle(self:GetAngles().y)) - self:GetLocalAngularVelocity().y * dt) / (dt * dt) 
		goalAngAccel.z = 2.0 * (math.AngleDifference(goalRoll, math.NormalizeAngle(self:GetAngles().z)) - self:GetLocalAngularVelocity().z * dt) / (dt * dt) 

		-- Clamp angular acceleration values
		goalAngAccel.x = math.Clamp(goalAngAccel.x, -300, 300) 
		goalAngAccel.y = math.Clamp(goalAngAccel.y, -120, 120)  -- Changed to 120 instead of 60, as in original comment 
		goalAngAccel.z = math.Clamp(goalAngAccel.z, -300, 300) 
	else 
		goalAngAccel.x	= 0 
		goalAngAccel.y = math.random(50,120) 
		goalAngAccel.z	= 0 
	end 
	
	-- limit angular accel changes to similate mechanical response times
	local angAccelAccel = Angle() 
	local dt = flInterval 
	angAccelAccel.x = (goalAngAccel.x - self.m_vecAngAcceleration.x) / dt 
	angAccelAccel.y = (goalAngAccel.y - self.m_vecAngAcceleration.y) / dt 
	angAccelAccel.z = (goalAngAccel.z - self.m_vecAngAcceleration.z) / dt 

	angAccelAccel.x = math.Clamp( angAccelAccel.x, -1000, 1000 ) 
	angAccelAccel.y = math.Clamp( angAccelAccel.y, -1000, 1000 ) 
	angAccelAccel.z = math.Clamp( angAccelAccel.z, -1000, 1000 ) 
	
	self.m_vecAngAcceleration = (self.m_vecAngAcceleration + angAccelAccel) * 0.1 

	local angVel = self:GetLocalAngularVelocity() 
	angVel = angVel + self.m_vecAngAcceleration * 0.1 
	angVel.y = math.Clamp( angVel.y, -120, 120 ) 
	
	-- Fix up pitch and yaw to tend toward small values 
	if ( m_lifeState == 1 and IsValid(self:GetCrashPoint() ) ) then 
		local flPitchDiff = math.random( -5, 5 ) - self:GetAngles().x 
		angVel.x = flPitchDiff * 0.1 
		local flRollDiff = math.random( -5, 5 ) - self:GetAngles().z 
		angVel.z = flRollDiff * 0.1 
	end 

	self:SetLocalAngularVelocity( angVel ) 

	-- local flAmt = math.Clamp( angVel.y, -30, 30 ) 
	-- local flRudderPose = math.Remap( flAmt, -30, 30, 45, -45 ) 
	-- self:SetPoseParameter( "rudder", flRudderPose ) 
	return angVel 
end 

--[[ 
function ENT:ComputeAngularVelocity(vecGoalUp, vecFacingDirection, flInterval) 
	local angVel = self:GetLocalAngularVelocity() 
	local flSpeed = self:GetAbsVelocity():Length() 
	local flDir = Vector( vecGoalUp.x, vecGoalUp.y, 0 ):Dot(Vector( self:GetAbsVelocity().x, self:GetAbsVelocity().y, 0 ) ) 
	if (flDir < 0 ) then flSpeed = -flSpeed end 
	local flDist = (self:NPC_GetDesiredPosition() - vecEst):Dot(vecGoalUp) 
	local flSlip = -((self:NPC_GetDesiredPosition() - vecEst):Dot(right)) 
	
	if flSlip > 0 then
		if self:GetLocalAngles().r > -30 and angVel.z > -15 then
			angVel.z = angVel.z - 4
		else
			angVel.z = angVel.z + 2
		end
	else
		if self:GetLocalAngles().r < 30 and angVel.z < 15 then
			angVel.z = angVel.z + 4
		else
			angVel.z = angVel.z - 2
		end
	end 
	self:ApplySidewaysDrag( right ) 
	self:ApplyGeneralDrag() 
	
	local MAX_FORCE = 80	
	local FORCE_POSDELTA = 12	
	local FORCE_NEGDELTA = 8 
	
	if self.m_flForce < MAX_FORCE and vecEst.z < self:NPC_GetDesiredPosition().z then 
		self.m_flForce = self.m_flForce + FORCE_POSDELTA 
	elseif self.m_flForce > 30 then 
		if (vecEst.z > self:NPC_GetDesiredPosition().z) then 
			self.m_flForce = self.m_flForce - FORCE_NEGDELTA 
		end 
	end 
	
	-- pitch forward or back to get to target
	-- -----------------------------------------
	-- Pitch is reversed since Half-Life! (sjb)
	-- -----------------------------------------
	if flDist > 0 and flSpeed < maxSpeed and self:GetLocalAngles().x + angVel.x < 40 then 
		-- lean forward
		angVel.x = angVel.x + 12.0 
		
	elseif (flDist < 0 && flSpeed > -50 && self:GetLocalAngles().x + angVel.x  > -20) then 
		-- lean backward
		angVel.x = angVel.x - 12.0 
	elseif (self:GetLocalAngles().x + angVel.x < 0) then 
		angVel.x = angVel.x + 4.0 
	elseif (self:GetLocalAngles().x + angVel.x > 0) then 
		angVel.x = angVel.x - 4.0 
	end 
	
	return angVel 
end 
--]] 

function ENT:UpdateTrackNavigation() 
	if !self.bLeading then 
		if self:GetCurWaypointPos() == Vector(0,0,0) then return end 
		self:NPC_UpdateTargetPosition() 
		self:NPC_UpdateCurrentTarget() 
	else 
		self:NPC_UpdateTargetPositionLeading() 
		self:NPC_UpdateCurrentTargetLeading() 
	end 
end 

function ENT:NPC_UpdateTargetPosition() 
	-- Don't update our target if we're being told to go somewhere
	if ( self.m_bForcedMove and !self.m_bPatrolBreakable ) then return end 

	-- Don't update our target if we're patrolling
	if ( self.m_bPatrolling ) then 
		-- If we have an enemy, and our patrol is breakable, stop patrolling
		if ( !self.m_bPatrolBreakable or !IsValid(self:GetEnemy() ) ) then return end 
		self.m_bPatrolling = false 
	end 
	local targetPos = self:GetTrackPatherTarget( ) 
	if targetPos == Vector(0,0,0) then return end 

	-- Not time to update again
	if self.m_flEnemyPathUpdateTime > CurTime() then return end 

	-- See if the target has moved enough to make us recheck
	local flDistSqr = ( targetPos - self.m_vecLastGoalCheckPosition ):LengthSqr() 
	if flDistSqr < self.m_flTargetDistanceThreshold * self.m_flTargetDistanceThreshold then return end 

	-- Find the best position to be on our path
	-- self.m_pDestPathTarget = 
	local pDest = self:NPC_BestPointOnPath(self:NPC_GetGoalTarget(), self.NPC_GetDesiredPosition(), self.m_flAvoidDistance, true, self.m_bChooseFarthestPoint) 
	if !IsValid(pDest) then return end 
	if pDest:GetPos() != self:NPC_GetDesiredPosition() then 
		
	end 
	--[[ 
	CPathTrack *pDest = BestPointOnPath( m_pCurrentPathTarget, targetPos, m_flAvoidDistance, true, m_bChooseFarthestPoint );

	if ( CPathTrack::ValidPath( pDest ) == NULL )
	{
		// This means that a valid path could not be found to our target!
//		Assert(0);
		return;
	}

	if ( pDest != m_pDestPathTarget )
	{
		// This is our new destination
		bool bMovingForward = IsForwardAlongPath( m_pCurrentPathTarget, pDest );
		if ( bMovingForward != m_bMovingForward )
		{
			// Oops! Need to reverse direction
			m_bMovingForward = bMovingForward;
			if ( pDest != m_pCurrentPathTarget )
			{
				SetupNewCurrentTarget( NextAlongCurrentPath( m_pCurrentPathTarget ) );
			}
		}
		m_pDestPathTarget = pDest;
	}

	-- Keep this goal point for comparisons later
	--]] 
	self.m_pDestPathTarget = IsValid(self:GetTarget()) and self:GetTarget() or self 
	self.m_vecLastGoalCheckPosition = targetPos 
	
	-- Only do this on set intervals
	self.m_flEnemyPathUpdateTime	= CurTime() + 1 
end 

function ENT:NPC_UpdateCurrentTarget() 
	-- Find the point along the line that we're closest to.
	local vecTarget = self:GetCurWaypointPos() -- const Vector &vecTarget = m_pCurrentPathTarget->GetAbsOrigin();
	local vecPoint, t = self:NPC_ClosestPointToCurrentPath() -- float t = ClosestPointToCurrentPath( &vecPoint );
	if (t < 1) and ( vecPoint:DistToSqr( vecTarget ) > self.m_flTargetTolerance * self.m_flTargetTolerance ) then 
		goto visualizeDebugInfo 
	end 
	-- Forced move is gone as soon as we've reached the first point on our path
	if ( self.m_bLeading ) then self.m_bForcedMove = false end 

	-- Trip our "path_track reached" output
	if m_pCurrentPathTarget != m_pLastPathTarget then 
		-- Get the path's specified max speed
		-- self.m_flPathMaxSpeed = self.m_pCurrentPathTarget:GetInternalVariable("m_flSpeed") 

		self.m_pCurrentPathTarget:Fire("AcceptInput",self,self) 
		self.m_pLastPathTarget = m_pCurrentPathTarget 
	end 

	if self.m_nPauseState == PAUSED_AT_POSITION then return end 

	if ( self.m_nPauseState == PAUSE_AT_NEXT_LOS_POSITION ) then 
		if self:Visible(self.m_pCurrentPathTarget) then self.m_nPauseState = PAUSED_AT_POSITION return end 
	end 

	-- Update our dest path target, if appropriate...
	if self.m_pCurrentPathTarget == self.m_pDestPathTarget then 
		self.m_bForcedMove = false 
		self:SelectNewDestTarget() 
	end 

	-- Did SelectNewDestTarget give us a new point to move to?
	if self.m_pCurrentPathTarget != self.m_pDestPathTarget then 
		-- Update to the next path, if there is one...
		self.m_pCurrentPathTarget = self:NextAlongCurrentPath( m_pCurrentPathTarget ) 
		if !m_pCurrentPathTarget then 
			self.m_pCurrentPathTarget = self.m_pLastPathTarget 
		end 
	else
		-- We're at rest (no patrolling behavior), which means we're moving forward now.
		self.m_bMovingForward = true;
	end 

	self:SetDesiredPosition( self.m_pCurrentPathTarget:GetPos() ) 
	self.m_vecSegmentStartSplinePoint = self.m_vecSegmentStartPoint 
	self.m_vecSegmentStartPoint = self.m_pLastPathTarget:GetPos() 

	::visualizeDebugInfo::	
	self:VisualizeDebugInfo( vecPoint, vecTarget ) 
end 

function ENT:NPC_GetAvoidanceSpheres() 
	-- create an empty table which will consist of vector = radius 
	local retTbl = {} 
	-- add npc_heli_avoidsphere positions and GetInternalVariable("m_flRadius") 
	for k,v in pairs(ents.FindByClass("npc_heli_avoidsphere")) do 
		retTbl[v:GetPos()] = v:GetInternalVariable("m_flRadius") 
	end 
	-- add danger sound positions and radius 
	-- local tblSound = sound.GetLoudestSoundHint(SOUND_DANGER,self:EyePos()) -- sadly this does not support sound bits 
	-- if tblSound then 
		-- retTbl[tblSound.origin] = tblSound.volume 
	-- end 
	
	for i = COND.HEAR_DANGER, COND.HEAR_SPOOKY do -- 50, 59 
		if self:HasCondition(i) then -- only call if capable of hearing such sounds 
			local tblSound = self:GetBestSoundHint(i) 
			if tblSound then 
				local sndOrigin = tblSound.origin 
				print(sndOrigin == self:WorldSpaceCenter()) 
				if sndOrigin == self:WorldSpaceCenter() then 
					-- treat this as owner's direction 
					if tblSound.owner and IsValid(tblSound.owner) then 
						local dir = tblSound.owner:EyePos() 
						dir = (dir - self:EyePos()):GetNormalized() 
						dir = dir * self:BoundingRadius() 
						sndOrigin = sndOrigin + dir 
					else 
						local dir = self:GetVelocity()*(-self:GetInternalVariable("m_flPrevAnimTime")) 
						sndOrigin = dir 
						-- sndOrigin 
					end 
				end 
				if i == COND.HEAR_DANGER then 
					retTbl[sndOrigin] = tblSound.volume 
				else 
					retTbl[sndOrigin] = tblSound.volume*0.1 
				end 
			end 
		end 
	end 
	
	
	-- add other sounds but with radius = radius * 0.1 
	
	-- return filled table 
	return retTbl 
end 

function ENT:NPC_GetAvoidanceBoxes() 
	local retTbl = {} -- create an empty table which will consist of vector = {vecMins, vecMaxs} 
	-- add npc_heli_avoidbox positions and {OBBMins(), OBBMaxs())  
	for k,v in pairs(ents.FindByClass("npc_heli_avoidbox")) do 
		retTbl[v:GetPos()] = {v:OBBMins(), v:OBBMaxs()} 
	end 
	-- add all npc locations with size of npc's {OBBMins() *1.5, OBBMaxs()*1.5} 
	
	for k,v in ents.Iterator() do 
		if v != self and (IsValid(v):GetParent() and v:GetParent() != v) and v:IsSolid() then 
		-- if v:IsNPC() or v:IsPlayer() or v:IsNextBot() then 
			retTbl[v:GetPos()] = {v:OBBMins()*1.5, v:OBBMaxs()*1.5} 
		end 
	end 
	
	-- return filled table 
	return retTbl 
end 

function ENT:NPC_ComputeAvoidanceSpheres(flEntityRadius, flAvoidTime) 
    -- Initialize the avoidance force vector
    local pVecAvoidForce = Vector(0, 0, 0) 

    -- Get the entity's velocity and position
    local vecEntityDelta = self:GetVelocity() * flAvoidTime
    local vecEntityCenter = self:WorldSpaceCenter()

    -- Get the list of avoidance spheres
    local avoidanceSpheres = self:NPC_GetAvoidanceSpheres()

    -- Iterate over each avoidance sphere
    for vecAvoidCenter, flRadius in pairs(avoidanceSpheres) do
        local flTotalRadius = flEntityRadius + flRadius
        local t1, t2 = util.IntersectRayWithSphere(vecEntityCenter, vecEntityDelta, vecAvoidCenter, flTotalRadius) 

        -- Check if the entity will intersect the avoidance sphere 
		if !t1 then 
            continue
        end 
		t2 = t2 and t2 or 0 

        -- Find the point of closest approach
        local flAverageT = (t1 + t2) * 0.5
        local vecClosestApproach = vecEntityCenter + vecEntityDelta * flAverageT

        -- Calculate the direction vector from the sphere center to the closest approach point
        local vecDir = vecClosestApproach - vecAvoidCenter
        local flZDist = vecDir.z
        local flDist = vecDir:Length()

        -- Ensure distance and direction are normalized
        local flDistToTravel
        if flDist < 0.01 then
            flDist = 0.01
            vecDir = Vector(0, 0, 1)
            flDistToTravel = flTotalRadius
        else
            vecDir = vecDir:GetNormalized() 

            -- make the chopper always avoid *above*
			-- That means if a force would be applied to push the chopper down,
			-- figure out a new distance to travel that would push the chopper up.
			-- we ignore this field 
			-- because we cannot returns spawnflags in NPC_GetAvoidanceSpheres() 
			
            -- if flZDist < 0.0 and !HasSpawnFlags(SF_AVOIDSPHERE_AVOID_BELOW) then
            --     vecDir.z = -vecDir.z
            --     local vecExitPoint = vecAvoidCenter + vecDir * flTotalRadius
            --     vecDir = vecExitPoint - vecClosestApproach
            --     flDistToTravel = vecDir:Length()
            -- else
            flDistToTravel = flTotalRadius - flDist
            -- end
        end

        -- Clamp t1 to avoid large time steps
        if t1 < 0.25 then
            t1 = 0.25
        end

        -- Calculate the avoidance force
        local flForce = 1.25 * flDistToTravel / t1
        vecDir = vecDir * flForce

        -- Add the calculated force to the total avoidance force
        pVecAvoidForce = pVecAvoidForce + vecDir
    end

    -- Return the total avoidance force
    return pVecAvoidForce
end 

local function IntersectInfiniteRayWithSphere(vecRayOrigin, vecRayDelta, vecSphereCenter, flRadius)
    -- Initialize the intersection times
    local t1, t2

    -- Compute the vector from the sphere center to the ray origin
    local vecSphereToRay = vecRayOrigin - vecSphereCenter

    -- Calculate the quadratic coefficients a, b, and c
    local a = vecRayDelta:Dot(vecRayDelta)

    -- If the ray has zero length, return early
    if a == 0.0 then
        t1, t2 = 0.0, 0.0
        return vecSphereToRay:LengthSqr() <= flRadius * flRadius, t1, t2
    end

    local b = 2 * vecSphereToRay:Dot(vecRayDelta)
    local c = vecSphereToRay:Dot(vecSphereToRay) - flRadius * flRadius
    local flDiscrim = b * b - 4 * a * c

    -- If the discriminant is negative, no intersection
    if flDiscrim < 0.0 then
        return false, t1, t2
    end

    -- Calculate the square root of the discriminant
    flDiscrim = math.sqrt(flDiscrim)

    -- Solve for the two intersection times t1 and t2
    local oo2a = 0.5 / a
    t1 = (-b - flDiscrim) * oo2a
    t2 = (-b + flDiscrim) * oo2a

    return true, t1, t2
end

function ENT:NPC_ComputeAvoidanceBoxes(flEntityRadius, flAvoidTime)
    -- Initialize the avoidance force vector
    local pVecAvoidForce = Vector(0, 0, 0)

    -- Get the entity's velocity and position
    local vecEntityDelta = self:GetVelocity() * flAvoidTime
    local vecEntityCenter = self:WorldSpaceCenter()
    local vecEntityEnd = vecEntityCenter + vecEntityDelta

    -- Normalize velocity direction
    local vecVelDir = self:GetVelocity():GetNormalized() 

    -- Get the list of avoidance boxes
    local avoidBoxes = self:NPC_GetAvoidanceBoxes()

    -- Iterate over each avoid box
    for vecAvoidCenter, boxBounds in pairs(avoidBoxes) do
        local boxMins = boxBounds[1]
        local boxMaxs = boxBounds[2]

        local flTotalRadius = flEntityRadius + math.max(boxMaxs.x - boxMins.x, boxMaxs.y - boxMins.y, boxMaxs.z - boxMins.z) / 2
        local t1, t2

        -- Check if the entity will intersect the avoidance box (similar to sphere intersection)
		local bIntersect, t1, t2 = IntersectInfiniteRayWithSphere(vecEntityCenter, vecEntityDelta, vecAvoidCenter, flTotalRadius, t1, t2) 
        if !bIntersect then
            continue
        end

        if t2 < 0.0 or t1 > 1.0 then
            continue
        end

        -- Transform the entity's position and direction into the box's local space using WorldToLocal
        local localCenter = WorldToLocal(vecEntityCenter, Angle(0,0,0), vecAvoidCenter, Angle(0,0,0))
        local localDelta = WorldToLocal(vecEntityDelta, Angle(0,0,0), vecAvoidCenter, Angle(0,0,0))

        -- Adjust the box's bounds based on the entity radius
        local vecBoxMin = boxMins - Vector(flEntityRadius, flEntityRadius, flEntityRadius)
        local vecBoxMax = boxMaxs + Vector(flEntityRadius, flEntityRadius, flEntityRadius)

        local hitPos, hitNormal, hitFraction = util.IntersectRayWithOBB(vecEntityCenter, vecEntityDelta, vecAvoidCenter, Angle(0, 0, 0), boxMins, boxMaxs)
        if !hitPos then
            continue
        end

        -- Closest point of approach between the entity's path and the box
        local flAverageT = (t1 + t2) * 0.5
        local vecClosestApproach = vecEntityCenter + vecEntityDelta * flAverageT

        -- Compute the force direction and limit sideways motion
        local vecDir = (vecClosestApproach - vecAvoidCenter)
        -- if (tr.plane.type != 3) or (tr.plane.normal[2] > 0.0) then
        if (hitNormal[2] > 0.0) then
			vecDir.x = vecDir.x * 0.1
			vecDir.y = vecDir.y * 0.1
        end

        local flZDist = vecDir.z
        local flDist = vecDir:Length()
        local flDistToTravel

        -- Handle distances and apply avoidance above the box
        if flDist < 10.0 then
            flDist = 10.0
            vecDir = Vector(0, 0, 1)
            flDistToTravel = flTotalRadius
        else
            -- Commented out code for avoiding below the box as requested
            -- if flZDist < 0.0 and not pBox:HasSpawnFlags(SF_AVOIDSPHERE_AVOID_BELOW) then
            --     vecDir.z = -vecDir.z
            --     local vecExitPoint = vecAvoidCenter + vecDir * flTotalRadius
            --     vecDir = vecExitPoint - vecClosestApproach
            --     flDistToTravel = vecDir:Length()
            -- else
            flDistToTravel = flTotalRadius - flDist
            -- end
        end

        -- Clamp t1 to avoid large time steps
        if t1 < 0.25 then
            t1 = 0.25
        end

        -- Calculate the avoidance force
        local flForce = 1.5 * flDistToTravel / t1
        vecDir = vecDir * flForce

        -- Add the calculated force to the total avoidance force
        pVecAvoidForce = pVecAvoidForce + vecDir
    end

    -- Return the total avoidance force
    return pVecAvoidForce
end 


function ENT:GetTrackPatherTarget() 
	local enemy = self:GetEnemy() 
	if IsValid(enemy) then 
		return enemy:BodyTarget(self:EyePos(),false) 
	end 
	return Vector(0,0,0) 
end 

function ENT:UpdateFacingDirection() 
	self.m_vecTargetPosition = IsValid(self:GetEnemy()) and self:GetEnemy():EyePos() or self.m_vecTargetPosition 
	local targetDir = (self.m_vecTargetPosition - self:GetPos()):GetNormalized() 
	local desiredDir = (self:NPC_GetDesiredPosition() - self:GetPos()):GetNormalized() 
	if !self:IsCrashing() and self:GetInternalVariable("m_flLastEnemyTime") > -5 then 
		self.m_vecDesiredFaceDir = targetDir 
	else 
		self.m_vecDesiredFaceDir = desiredDir 
	end 
end 

function ENT:UpdateDesiredPosition() 
	local curwaypoint = self:GetCurWaypointPos() 
	if curwaypoint != Vector(0,0,0) then 
	
		if self.bNewPath == false then 
			self.bNewPath = true 
			self.m_vecSegmentStartPoint = self:GetPos() 
			self.m_vecSegmentStartSplinePoint = self:GetCurWaypointPos() 
		end 
	
		self:NPC_SetDesiredPosition(curwaypoint) 
		
		local vecPoint, t = self:NPC_ClosestPointToCurrentPath() -- float t = ClosestPointToCurrentPath( &vecPoint );
		-- if (t < 1) and ( vecPoint:DistToSqr( curwaypoint ) > self.m_flTargetTolerance * self.m_flTargetTolerance ) then 
			-- print("distance is higher") 
			-- print("t:",t) 
		-- end 
		print("vecPoint:DistToSqr( curwaypoint )", vecPoint:DistToSqr( curwaypoint )) 
		
		if self:IsGoalActive() then 
			local dist = self:GetCurWaypointPos():Distance(self:GetPos()) 
			if dist < self:BoundingRadius() or !((t < 1) and ( vecPoint:DistToSqr( curwaypoint ) > self.m_flTargetTolerance * self.m_flTargetTolerance )) then 
				if self:GetNextWaypointPos() != Vector(0,0,0) then 
					self.m_vecSegmentStartPoint = self:GetCurWaypointPos() -- next waypoint 
					self.m_vecSegmentStartSplinePoint = self:GetNextWaypointPos() -- point between curwaypoint and nextwaypoint 
					self:AdvancePath() 
				else 
					self:OnMovementComplete() 
					self:ClearGoal() 
				end 
			end 
		end 
	-- elseif IsValid(self:GetTrackPatherTargetEnt() then return self:GetEnemy():GetPos() end 
	elseif self.bNewPath then 
		self.bNewPath = false 
	end 
end 

function ENT:CalcDoppler(snd) 
	local dopper_type = 3 
	local pitch = 0
	local viewent = GetViewEntity()
	if IsValid(LocalPlayer():GetObserverTarget()) then viewent = LocalPlayer():GetObserverTarget() end 
	if isfunction(viewent.GetVehicle) and IsValid(viewent:GetVehicle()) then viewent = viewent:GetVehicle() end 
	if doppler_type == 1 then
		local vel = self:GetVelocity() -- Doppler code in razorblades
		local plyvel = viewent:GetVelocity() 
		local dist = self:GetPos() - viewent:EyePos() 
		
		local vr = plyvel:Dot(dist) / dist:Length() 
		local vs = vel:Dot(dist) / dist:Length() 
		local c = 2000 
		
		local pitch = (c + vr) / (c + vs)
		local doppler = math.Clamp(pitch * 300, 64, 160)
		pitch = doppler 
		-- print(doppler)
	elseif doppler_type == 2 then
		local velocity = self:GetVelocity() -- AirVehicles code
		local pitch = self:GetVelocity():Length()
		------------------------------Doppler effect idea -> Thanks @ Jumper Code 
		local doppler_effect = 0
		local direction = (viewent:GetPos() - self:GetPos() )
		local doppler_effect = velocity:Dot(direction)/(150*direction:Length())
		pitch = math.Clamp(70 + pitch/25,60,120) + doppler_effect 
		-- print(math.Clamp(70 + pitch/25,60,120) + doppler_effect)
	elseif doppler_type == 3 then
	-- Valve's doppler shift code, in cbasehelicopter.cpp
		local subtdir = viewent:GetPos()-self:GetPos() -- VectorSubtract( pPlayer->GetAbsOrigin(), GetAbsOrigin(), dir );
		local ndir = subtdir:GetNormalized()

		local velReceiver = viewent:GetAbsVelocity():Dot(ndir)
		local velTransmitter = -(self:GetAbsVelocity():Dot(ndir))
		local iPitch = math.ceil(100 * ((1 - velReceiver / 13049) / (1 + velTransmitter / 13049)))
		-- print("using real doppler")
		-- print("velReceiver is:", velReceiver)
		-- print("velTransmitter is:", velTransmitter)
		local clamped_iPitch = math.Clamp(iPitch, 64, 160)
		pitch = clamped_iPitch 
		-- print("clamped_iPitch is:", clamped_iPitch)
	else
		local subtdir = viewent:GetPos()-self:GetPos() -- VectorSubtract( pPlayer->GetAbsOrigin(), GetAbsOrigin(), dir ); 
		local ndir = subtdir:GetNormalized() 
		local relV = ((self:GetAbsVelocity() - viewent:GetAbsVelocity()):Dot(ndir)) -- valve calls this "bogus" doppler shift 
		local iPitch = math.ceil(100 + relV / 50) 
		-- print("using bogus doppler") 
		local clamped_iPitch = math.Clamp(iPitch, 64, 160) 
		pitch = clamped_iPitch 
		-- print("clamped_iPitch is:", clamped_iPitch) 
	end 
	return pitch 
end 

function ENT:NPC_ComputePathTangent(t) 
    -- Clamp t between 0.0 and 1.0
    t = math.Clamp(t, 0.0, 1.0) 

    -- If no next path, set it to current path
    local vecNextTrack = self:GetNextWaypointPos() != Vector(0,0,0) and self:GetNextWaypointPos() or self:GetCurWaypointPos() 

    -- Call the Catmull-Rom spline tangent function with the necessary points 
	local pVecTangent = CatmullRomSplineTangent( 
        self.m_vecSegmentStartSplinePoint, 
        self.m_vecSegmentStartPoint, 
        self:GetCurWaypointPos(), 
        self:GetNextWaypointPos(), 
        t 
    ) 

    -- Normalize the resulting vector 
    pVecTangent = pVecTangent:GetNormalized() 

    return pVecTangent 
end 

function ENT:NPC_FlyToPathTrack(path) 
	if !isstring(path) then return false end 
	local pGoalEnt = ents.FindByName(path) 
	if !table.IsEmpty(pGoalEnt) then 
		pGoalEnt = pGoalEnt[1] 
		self:SetTarget(pGoalEnt) 
		self:SetKeyValue("target", pGoalEnt:GetName()) 
		self:Fire("wake") 
		return true 
	end 
	print(self,  "Could not find path_track", path) 
	return false 
end 

function ENT:GetSoundInterests() 
	return SOUND_WORLD + SOUND_COMBAT + SOUND_PLAYER + SOUND_PLAYER_VEHICLE + SOUND_DANGER + SOUND_PHYSICS_DANGER + SOUND_BULLET_IMPACT + SOUND_MOVE_AWAY 
end 

function ENT:OnRemove() if self.rotorsound then self.rotorsound:Stop() self.rotorsound = nil end end 
function ENT:GetTrackPatherTargetEnt() return self:GetEnemy() end 
function ENT:IsCrashing() return false end 
function ENT:RunAI() 
	self:SetSaveValue("m_flDistTooFar",16384) 
	self:SetMaxLookDistance(16384) 
	return true 
end 

function ENT:SelectSchedule() end 
function ENT:NPC_GetMaxRange1Dist() return self:GetInternalVariable("m_flDistTooFar") end 
function ENT:NPC_ShouldDropBombs() return false end 
function ENT:NPC_SetLeadingDistance(flDist) self.flLeadDistance = flDist or 0 end 
function ENT:NPC_GetLeadingDistance(flDist) return self.flLeadDistance or 0 end 
function ENT:NPC_SetDesiredPosition(m_vecDesiredPosition) self.m_vecDesiredPosition = m_vecDesiredPosition or self:GetPos() end 
function ENT:NPC_GetDesiredPosition(flDist) return self.m_vecDesiredPosition or self:GetCurWaypointPos() end 
function ENT:NPC_SetFarthestPathDist(flDist) self.m_flFarthestPathDist = flDist or 0 end 

--[[ 
function ENT:UApache_Think() 
	-- fly 
	self:UApache_OverrideMove(self:GetSaveTable().m_flTimeLastMovement) 
	-- take aim 
	
	-- fire 
end 

function ENT:UApache_Simulate() 
	if !self.lastmovesimulate then self.lastmovesimulate = CurTime()-0.1  end 
	local deltaTime = CurTime() - self.lastmovesimulate 
	self.lastmovesimulate = CurTime() 
	-- move. 
	local actualVelocity = self:GetVelocity() 
	local actualAngularVelocity = self:GetLocalAngularVelocity() 
	local linear = (self.m_vCurrentVelocity - actualVelocity) * (0.1 / deltaTime) 

	/*
	DevMsg("Sim %d : %5.1f %5.1f %5.1f\n", count++,
		self.m_vCurrentVelocity.x - actualVelocity.x, 
		self.m_vCurrentVelocity.y - actualVelocity.y, 
		self.m_vCurrentVelocity.z - actualVelocity.z );
	*/

	-- do angles.
	local actualAngles = self:GetAngles() 

	-- FIXME: banking currently disabled, forces simple upright posture 
	local angular = Angle() 
	angular.x = (math.AngleDifference( self.m_vCurrentBanking.z, actualAngles.z ) - actualAngularVelocity.x) * (1 / deltaTime) 
	angular.y = (math.AngleDifference( self.m_vCurrentBanking.x, actualAngles.x ) - actualAngularVelocity.y) * (1 / deltaTime) 

	-- turn toward target
	angular.z = math.AngleDifference( self.m_fHeadYaw, actualAngles.y + actualAngularVelocity.z * 0.1 ) * (1 / (deltaTime)*0.1) 
	print( self.m_fHeadYaw, actualAngles.y , actualAngularVelocity.z * 0.1  , 1 / (deltaTime)*0.1) 

	-- angular = m_vCurrentAngularVelocity - actualAngularVelocity;

	-- DevMsg("Sim %d : %.1f %.1f %.1f (%.1f)\n", count++, actualAngles.x, actualAngles.y, actualAngles.z, m_fHeadYaw );

	-- FIXME: remove the stuff from MoveExecute();
	-- FIXME: check MOVE?
	self:UApache_ClampMotorForces( linear, angular ) 
	print(linear,angular) 
	self:SetLocalVelocity(linear) 
	-- self:SetLocalAngularVelocity(angular) 
end 

function ENT:UApache_OverrideMove( flInterval ) 
	if self.m_nFlyMode == UAPACHE_FLY_DIVE then 
		-- self:MoveToDiveBomb( flInterval ) 
	else 
		local vMoveTargetPos = nil 
		local pMoveTarget = nil 
		if IsValid(self:GetTarget()) then 
			pMoveTarget = self:GetTarget() 
		elseif IsValid(self:GetEnemy()) then 
			pMoveTarget = self:GetEnemy() 
		end 
		if IsValid(self:GetEnemy()) then 
			 vMoveTargetPos = self:GetEnemy():EyePos() 
		-- else vMoveTargetPos = self:GetCurWaypointPos() 
		end 
		self.uapache_fly_clear = false 
		self.uapache_fly_blocked = false 
		-- See if we can fly there directly
		if IsValid(pMoveTarget) then 
			local tr = util.TraceHull( { start = self:EyePos(),endpos = pMoveTarget:WorldSpaceCenter(),maxs = self:OBBMaxs(), mins = self:OBBMins(),filter = self , mask = MASK_NPCSOLID_BRUSHONLY} ) 
			local targetDist = (1.0-tr.Fraction)*(self:EyePos() - vMoveTargetPos):Length() 
			if tr.Entity == pMoveTarget and targetDist < 50 then 
				self.uapache_fly_clear = true 
			else 
				self.uapache_fly_blocked = true 
			end 
		end 
		local goal = self:UApache_GetGoalTarget() 
		if !goal:IsZero() then 
		-- if ( OverridePathMove( pMoveTarget, flInterval ) )
			-- {
				-- BlendPhyscannonLaunchSpeed();
				-- return true;
			-- }
			
		elseif self.m_nFlyMode == UAPACHE_FLY_ATTACK then 
			self:UApache_MoveToAttack( flInterval ) 
		elseif goal:IsZero() then -- we won't be using getcurwaypointpos 
			local myDecay = 9.5 
			self:UApache_Decelerate( flInterval, myDecay )  
		end 
		self:UApache_MoveExecute_Alive( flInterval ) 
	end 
end 

function ENT:UApache_MoveExecute_Alive( flInterval ) -- flInterval means the last time you moved. m_flTimeLastMovement 
	local flNoiseScale = 3 
	print("called MoveExecute_Alive") 
	if self.m_nFlyMode != UAPACHE_FLY_DIVE then 
		self:UApache_SetCurrentVelocity( self:UApache_GetCurrentVelocity() + self:UApache_VelocityToAvoidObstacles(flInterval) ) 
	else 
		-- self:AttackDivebombCollide(flInterval) 
		-- flNoiseScale = flNoiseScale* 4 
	end 
	if self:GetPhysicsObject():IsValid() and self:GetPhysicsObject():IsAsleep() then 
		self:GetPhysicsObject():Wake() 
	end 
	self:UApache_AddNoiseToVelocity(flNoiseScale) 
	-- self:UApache_AdjustVelocity() 
	local maxspeed = self:UApache_GetMaxSpeed() 
	if IsValid(self:GetEnemy()) then maxspeed = maxspeed * 2 end 
	if self.m_nFlyMode == UAPACHE_FLY_DIVE then maxspeed = 1 end 
	self:UApache_LimitSpeed( maxspeed ) 
	self:UApache_UpdateHead( flInterval ) 
end 

function ENT:UApache_MoveToAttack( flInterval ) 
	print("called MoveToAttack") 
	if !IsValid(self:GetEnemy()) then return end 
	if flInterval <= 0 then return end 
	local targetPos = self:GetEnemyLastKnownPos() 
	local idealPos = self:UApache_IdealGoalForMovement( targetPos, self:EyePos(), self:UApache_GetGoalDistance(), self.UApache_Near_Dist ) 
	self:UApache_MoveToTarget( flInterval, idealPos ) 
end 

function ENT:UApache_IdealGoalForMovement( goalPos, startPos, idealRange, idealHeightDiff )  
	print("called IdealGoalForMovement") 
	local vMoveDir = vector_origin 
	if !self:UApache_GetGoalDirection( vMoveDir ) then 
		vMoveDir = ( goalPos - startPos ) 
		vMoveDir.z = 0 
		vMoveDir = vMoveDir:GetNormalized() 
	end 
	-- Move up from the position by the desired amount
	local vIdealPos = goalPos + Vector( 0, 0, idealHeightDiff ) + ( vMoveDir * -idealRange ) 
	-- Trace down and make sure we can fit here 
	local tr = util.TraceHull({start = vIdealPos, endpos = vIdealPos - Vector( 0, 0, self:UApache_MinGroundDist() ), self:OBBMins(),self:OBBMaxs(),mask = MASK_NPCSOLID, filter = self, collisiongroup = COLLISION_GROUP_NONE }) 
	-- Move up otherwise 
	if tr.Fraction < 1.0 then 
		vIdealPos.z = vIdealPos.z + ( self:UApache_MinGroundDist() * ( 1.0 - tr.Fraction ) ) 
	end 
	return vIdealPos 
end 

function ENT:UApache_GetGoalDirection( vOut )
	print("called GetGoalDirection") 
	local target = self:GetTarget() 

	if !IsValid(target) then 
		return false 
	end 

	if target:GetClass() == "info_hint_air" or target:GetClass() == "info_target" then 
		-- local vOut = target:GetForward() 
		return true 
	end 
	return false 
end 

function ENT:UApache_GetGoalDistance() 
	print("called GetGoalDistance") 
	if self.m_flGoalOverrideDistance != 0.0 then return self.m_flGoalOverrideDistance end 
	if self.m_nFlyMode == UAPACHE_FLY_ATTACK then 
		local goalDist = ( self.UApache_Near_Dist + ( ( self.UApache_Far_Dist - self.UApache_Near_Dist ) / 2 ) ) 
		if IsValid(self:GetEnemy()) and self:GetEnemy().IsSuitEquipped and self:GetEnemy():IsSuitEquipped() then 
			goalDist = goalDist * 0.5 
		end 
		return goalDist 
	end 
	return 128 
end 

function ENT:UApache_MoveToTarget( flInterval, vecMoveTarget ) 
	print("called MoveToTarget") 
	local enemy = self:GetEnemy() 
	if enemy != NULL  then 
		-- Otherwise at our enemy
		self:UApache_TurnHeadToTarget( flInterval, enemy:EyePos() ) 
	else
		-- Otherwise face our motion direction
		self:UApache_TurnHeadToTarget( flInterval, vecMoveTarget ) 
	end 
	local myAccel = nil 
	local myZAccel = 400.0 
	local myDecay  = 0.15 
	local vecCurrentDir = (self:UApache_GetCurrentVelocity()):GetNormalized() 
	local targetDir = vecMoveTarget - self:EyePos() 
	local flDist = targetDir:Length() 
	targetDir:GetNormalized() 
	local flDot = targetDir:Dot(vecCurrentDir) 
	if flDot > 0.25 then 
		 myAccel = 250 
	else myAccel = 128 
	end 
	if myAccel > flDist / flInterval then 
		myAccel = flDist / flInterval 
	end 
	if myZAccel > flDist / flInterval then 
		myZAccel = flDist / flInterval 
	end 
	self:UApache_MoveInDirection( flInterval, targetDir, myAccel, myZAccel, myDecay ) 
	local right = self:GetRight() 
	self.m_vCurrentBanking.x	= targetDir.x 
	self.m_vCurrentBanking.z	= 120 * right:Dot( targetDir ) 
	self.m_vCurrentBanking.y	= 0 
	local speedPerc = math.Remap(self:UApache_GetCurrentVelocity():Length(), 0, self:UApache_GetMaxSpeed(), 0.0, 1.0) 
	speedPerc = math.Clamp(speedPerc,0,1) 
	self.m_vCurrentBanking = speedPerc* self.m_vCurrentBanking 
	
end 

-- ai_basenpc_physicsflyer.h code below 

function ENT:UApache_MoveInDirection( flInterval, targetDir, accelXY, accelZ, decay) 
	print("called MoveInDirection") 

	decay = ExponentialDecay( decay, 1.0, flInterval ) 
	accelXY = accelXY * flInterval 
	accelZ  = accelZ * flInterval 

	self.m_vCurrentVelocity.x = ( decay * self.m_vCurrentVelocity.x + accelXY * targetDir.x ) 
	self.m_vCurrentVelocity.y = ( decay * self.m_vCurrentVelocity.y + accelXY * targetDir.y ) 
	self.m_vCurrentVelocity.z = ( decay * self.m_vCurrentVelocity.z + accelZ  * targetDir.z ) 
	return flInterval, targetDir, accelXY, accelZ, decay 
end 

function ENT:UApache_MoveToLocation( flInterval, target, accelXY, accelZ, decay )
	print("called MoveToLocation") 
	local targetDir = (target - self:WorldSpaceCenter()):GetNormalized()
	
	flInterval, targetDir, accelXY, accelZ, decay = self:UApache_MoveInDirection(flInterval, targetDir, accelXY, accelZ, decay) 
	return flInterval, targetDir, accelXY, accelZ, decay 
end 

function ENT:UApache_Decelerate( flInterval, decay )
	print("called Decelerate") 
	decay = decay * flInterval 
	self.m_vCurrentVelocity.x = (decay * self.m_vCurrentVelocity.x) 
	self.m_vCurrentVelocity.y = (decay * self.m_vCurrentVelocity.y) 
	self.m_vCurrentVelocity.z = (decay * self.m_vCurrentVelocity.z) 
end 

function ENT:UApache_AddNoiseToVelocity( noiseScale ) 
	print("called AddNoiseToVelocity") 
	if !noiseScale then noiseScale = 1 end 
	if self.m_vNoiseMod.x != 0 then 
		self.m_vCurrentVelocity.x = self.m_vCurrentVelocity.x + noiseScale*math.sin(self.m_vNoiseMod.x * CurTime() + self.m_vNoiseMod.x) 
	end 
	
	if self.m_vNoiseMod.y != 0 then 
		self.m_vCurrentVelocity.y = self.m_vCurrentVelocity.y + noiseScale*math.cos(self.m_vNoiseMod.y * CurTime() + self.m_vNoiseMod.y) 
	end 

	if self.m_vNoiseMod.z != 0 then 
		self.m_vCurrentVelocity.z = self.m_vCurrentVelocity.z - noiseScale*math.cos(self.m_vNoiseMod.z * CurTime() + self.m_vNoiseMod.z) 
	end 
end 
	
function ENT:UApache_LimitSpeed( zLimit, maxSpeed ) 
	print("called LimitSpeed") 
	if !maxSpeed then maxSpeed = self:GetKeyValues().speed end 
	if self.m_vCurrentVelocity:Length() > maxSpeed then 
		local curvel = self.m_vCurrentVelocity:GetNormalized() 
		curvel = curvel * maxSpeed 
		self.m_vCurrentVelocity = curvel 
	end 
	if zLimit and zLimit > 0 and self.m_vCurrentVelocity.z < -zLimit then 
		self.m_vCurrentVelocity.z = -zLimit 
	end 
end 

function ENT:UApache_ClampMotorForces( linear ) 
	print("called ClampMotorForces") 
	linear.x = math.Clamp( linear.x, -3000, 3000 ) 
	linear.y = math.Clamp( linear.y, -3000, 3000 ) 
	linear.z = math.Clamp( linear.z, -3000, 3000 ) 
	-- linear.z = linear.z + 800 
	return linear 
end 

-- ai_basenpc_physicsflyer.cpp code below 

function ENT:UApache_ClampYaw( yawSpeedPerSec, current, target, timee ) 
	print("called ClampYaw") 
	if current != target then
		local speed = yawSpeedPerSec * timee 
		local move = target - current 

		if target > current then 
			if move >= 180 then 
				move = move - 360 
			
		elseif move <= -180 then 
				move = move + 360 
			end 
		end 

		if move > 0 then 
		-- turning to the npc's left
			if move > speed then 
				move = speed 
		elseif move < -speed then 
		-- turning to the npc's right
				move = -speed 
			end 
		end 
		
		return anglemod(current + move) 
	end 
	return target 
end 

function ENT:UApache_TurnHeadToTarget( flInterval, MoveTarget ) 
	-- i did not understand the code in ai_basenpc_physicsflyer.cpp 
	-- so instead i implemented ai_basenpc_flyer.cpp code 
	local flDestYaw = self:UApache_VecToYaw(MoveTarget - self:EyePos()) 
	local newYaw = self:UApache_ClampYaw((self:UApache_GetHeadTurnRate() * 10), self.m_fHeadYaw, flDestYaw, CurTime()) -- broken  
	if newYaw != m_fHeadYaw then m_fHeadYaw = newYaw end 
	-- self:SetBoneController(0,m_fHeadYaw-100) 
end 

function ENT:UApache_VelocityToAvoidObstacles( flInterval ) 
	-------------------------------- 
	-- Avoid banging into stuff 
	-------------------------------- 
	local vTravelDir = self.m_vCurrentVelocity * flInterval 
	local endPos = self:EyePos() + vTravelDir 
	local tr = util.TraceLine({ start = self:EyePos(), endpos = endPos, filter = self, mask = MASK_NPCSOLID }) 
	if tr.Fraction != 1 then 
		local vBounce = tr.HitNormal * 0.5 * self.m_vCurrentVelocity:Length() 
		return vBounce 
	end 
	// --------------------------------
	// Try to remain above the ground.
	// --------------------------------
	local flMinGroundDist = self:UApache_MinGroundDist() 
	local tr2 = util.QuickTrace(self:EyePos(),Vector(0,0,-flMinGroundDist),self) 
	if tr2.Fraction < 1 then 
		 -- Clamp velocity 
		 if tr2.Fraction < 0.1 then tr2.Fraction = 0.1 end 
		 return Vector(0,0,50/tr.Fraction) 
	end
	return vector_origin 
end 

local function UTIL_VecToYaw(vec) 
	if vec.x == 0 and vec.y == 0 then return 0 end 
	local yaw = math.atan2(vec.y,vec.x) 
	yaw = math.deg(yaw) 
	if yaw < 0 then yaw = yaw + 360 end 
	return yaw 
end 

function ENT:UApache_VecToYaw(vecDir) 

	if (vecDir.x == 0 and vecDir.y == 0 and vecDir.z == 0) then 
		return self:GetLocalAngles().y 
	end 
	return UTIL_VecToYaw( vecDir ) 

end 

function ENT:UApache_GetHeadTurnRate() if IsValid(self:GetEnemy()) then return 800 else return 350 end end 
function ENT:UApache_GetCurrentVelocity() return self.m_vCurrentVelocity end 
function ENT:UApache_SetCurrentVelocity( vel ) self.m_vCurrentVelocity = vel end 
function ENT:UApache_GetNoiseMod() return self.m_vNoiseMod end 
function ENT:UApache_SetNoiseMod(vec) self.m_vNoiseMod = vec end 
function ENT:UApache_GetMaxSpeed() return self.UApache_Max_Speed end 
function ENT:UApache_UpdateHead() end 
function ENT:UApache_MinGroundDist() return 256 end 
function ENT:OnTakeDamage(dmginfo) return 0 end 

-- custom functions 
function ENT:UApache_GoalTargetUpdated(vec) self:SetSaveValue("m_flTimeLastMovement",0) end 
function ENT:UApache_GetGoalTarget() return self:GetSaveTable().m_vecStoredPathGoal end 
function ENT:UApache_SetGoalTarget(vec) 
	if IsEntity(vec) then 
		 self:SetSaveValue("m_vecStoredPathGoal",vec:NearestPoint(self:NearestPoint(vec))) 
	else self:SetSaveValue("m_vecStoredPathGoal",vec) 
	end 
	self:UApache_GoalTargetUpdated(vec) 
end 

--]] 
