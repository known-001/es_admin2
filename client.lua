local group = "user"
local states = {}
states.frozen = false
states.frozenPos = nil
local idPlayers = 0
local namePlayers = '' -- nil until server talks to client
local players = {} -- stores player data
ESX              = nil
local PlayerData = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer   
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

RegisterKeyMapping("adminpanel", "Admin Menu", "keyboard", 'INSERT')

RegisterNetEvent('orp:admin:AdminPlayerList')
AddEventHandler('orp:admin:AdminPlayerList', function(names, ids)
    idPlayers = ids
    namePlayers = names
	table.insert(players, {id = idPlayers, name = namePlayers})
	print('This is working')
end)

RegisterCommand("adminpanel",function()
	if group ~= "user" then
		TriggerServerEvent('orp:admin:AdminPlayerList') -- populates table
		Citizen.Wait(1000)
	   SetNuiFocus(true, true)
	   SendNUIMessage({type = 'open', players = players})
	end
end,false)

RegisterNetEvent('orp:admin:setGroup')
AddEventHandler('orp:admin:setGroup', function(g)
	group = g
end)

local onduty = false

RegisterNUICallback('duty', function(data, cb)
	if group ~= 'user' then
		if not onduty then
			onduty = true
			print('working')
			SetPedComponentVariation(PlayerPedId(), 9, 1, 3)
			TriggerEvent("pNotify:SendNotification",{
				text = "<h2>Admin Notification</h2>" .. "<h1>"..GetPlayerName(player).."</h1>" .. "<p>You are now on duty as a admin.</p>",
				type = "success",
				timeout = (1000),
				layout = "centerLeft",
				queue = "global"
			})
		else
			onduty = false
			print('working1')
			SetPedComponentVariation(PlayerPedId(), 9, 0, 0)
			TriggerEvent("pNotify:SendNotification",{
				text = "<h2>Admin Notification</h2>" .. "<h1>"..GetPlayerName(player).."</h1>" .. "<p>You are now off duty as a admin.</p>",
				type = "success",
				timeout = (1000),
				layout = "centerLeft",
				queue = "global"
			})
		end
	end
end)

RegisterNUICallback('close', function(data, cb)
	SetNuiFocus(false)
	players = {}
end)

RegisterCommand('load_group', function(source)
	TriggerEvent('orp:admin:setGroup')
end)

RegisterNUICallback('set', function(data, cb)
	TriggerServerEvent('orp:admin:set', data.type, data.user, data.param)
end)

RegisterNUICallback('kick', function(data, cb)

	if onduty then

		local user = data.user

		local msg = data.param

		local name = GetPlayerName(player)

		TriggerServerEvent('orp:admin:kick', user, msg, name)

	else
		
		TriggerEvent("pNotify:SendNotification",{
			text = "<h2>Admin Notification</h2>" .. "<h1>ADMIN:</h1>" .. "<p>You must be out of roleplay</p>",
			type = "success",
			timeout = (1000),
			layout = "centerLeft",
			queue = "global"
		})

	end
end)

RegisterNUICallback('ban', function(data, cb)

	if onduty then

		local user = data.user

		local reason = data.param

		local time = data.length

		local name = GetPlayerName(player)

		TriggerServerEvent('orp:admin:ban', user, reason, name, time)
		
	else 

		TriggerEvent("pNotify:SendNotification",{
			text = "<h2>Admin Notification</h2>" .. "<h1>ADMIN:</h1>" .. "<p>You must be out of roleplay</p>",
			type = "success",
			timeout = (1000),
			layout = "centerLeft",
			queue = "global"
		})

	end

end)

RegisterNUICallback('spectate', function(data, cb)

	local user = data.user

	local name = GetPlayerName(player)

	TriggerServerEvent('orp:admin:spectate', user, name)

end)

RegisterNUICallback('quick', function(data, cb)

	if onduty then

		if data.type == "slay_all" or data.type == "bring_all" or data.type == "slap_all" then

			TriggerServerEvent('orp:admin:all', data.type)

		else

			TriggerServerEvent('orp:admin:quick', data.id, data.type)
			
		end

	else

		TriggerEvent("pNotify:SendNotification",{
			text = "<h2>Admin Notification</h2>" .. "<h1>ADMIN:</h1>" .. "<p>You must be out of roleplay</p>",
			type = "success",
			timeout = (1000),
			layout = "centerLeft",
			queue = "global"
		})

	end

end)

-- Duty Script 

RegisterNetEvent('orp:admin:quick')
AddEventHandler('orp:admin:quick', function(t, target)
	if t == "slay" then SetEntityHealth(PlayerPedId(), 0) end
	if t == "goto" then SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target)))) end
	if t == "bring" then 
		states.frozenPos = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target)))
		SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target)))) 
	end
	if t == "freeze" then
		local player = PlayerId()

		local ped = PlayerPedId()

		states.frozen = not states.frozen
		states.frozenPos = GetEntityCoords(ped, false)

		if not state then
			if not IsEntityVisible(ped) then
				SetEntityVisible(ped, true)
			end

			if not IsPedInAnyVehicle(ped) then
				SetEntityCollision(ped, true)
			end

			FreezeEntityPosition(ped, false)
			SetPlayerInvincible(player, false)
		else
			SetEntityCollision(ped, false)
			FreezeEntityPosition(ped, true)
			SetPlayerInvincible(player, true)

			if not IsPedFatallyInjured(ped) then
				ClearPedTasksImmediately(ped)
			end
		end
	end
end)

local clip = false

RegisterKeyMapping("clip", "Noclip", "keyboard", 'F7')

RegisterCommand('clip', function()
	if group ~= 'user' then
		if onduty then
			TriggerEvent('orp:admin:noclip')
			clip = true
		else
			TriggerEvent("pNotify:SendNotification",{
				text = "<h2>Admin Notification</h2>" .. "<h1>ADMIN:</h1>" .. "<p>You must be out of roleplay to Noclip.</p>",
				type = "success",
				timeout = (1000),
				layout = "centerLeft",
				queue = "global"
			})
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		if(states.frozen)then
			ClearPedTasksImmediately(PlayerPedId())
			SetEntityCoords(PlayerPedId(), states.frozenPos)
		else
			Citizen.Wait(200)
		end
	end
end)

RegisterNetEvent('orp:admin:freezePlayer')
AddEventHandler("orp:admin:freezePlayer", function(state)
	local player = PlayerId()

	local ped = PlayerPedId()

	states.frozen = state
	states.frozenPos = GetEntityCoords(ped, false)

	if not state then
		if not IsEntityVisible(ped) then
			SetEntityVisible(ped, true)
		end

		if not IsPedInAnyVehicle(ped) then
			SetEntityCollision(ped, true)
		end

		FreezeEntityPosition(ped, false)
		SetPlayerInvincible(player, false)
	else
		SetEntityCollision(ped, false)
		FreezeEntityPosition(ped, true)
		SetPlayerInvincible(player, true)

		if not IsPedFatallyInjured(ped) then
			ClearPedTasksImmediately(ped)
		end
	end
end)

RegisterNetEvent('orp:admin:teleportUser')
AddEventHandler('orp:admin:teleportUser', function(x, y, z)
	SetEntityCoords(PlayerPedId(), x, y, z)
	states.frozenPos = {x = x, y = y, z = z}
end)

-- Start of anticheat

--For blacklisted cars

local sentmessage = false

Citizen.CreateThread(function()
	while true do
		if IsPedInAnyVehicle(PlayerPedId(), true) then
			local veh = GetVehiclePedIsIn(PlayerPedId(), false)
			if DoesEntityExist(veh) and IsEntityAVehicle(veh) and not IsEntityDead(veh) then
				if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
					for _,car in pairs(Config.Blcars) do
						local model = GetEntityModel(veh)
						if GetHashKey(car) == model and not sentmessage then
							local reason = car
							local name = GetPlayerName(source)
							TriggerServerEvent('orp:admin:blcar', reason, name)
							sentmessage = true
							Wait(30000)
							sentmessage = false
						end
					end
				end
			end
		end
		Citizen.Wait(10)
	end
end)

--For blacklisted weapons

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)

		playerPed = GetPlayerPed(-1)
		if playerPed then
			nothing, weapon = GetCurrentPedWeapon(playerPed, true)

			if isWeaponBlacklisted(weapon) then
				local reason = weapon
				local name = GetPlayerName(source)
				TriggerServerEvent('orp:admin:blweapon', name, reason)	
			end
		end
	end
end)

function isWeaponBlacklisted(model)
	for _, blacklistedWeapon in pairs(Config.Blweapons) do
		if model == GetHashKey(blacklistedWeapon) then
			return true
		end
	end

	return false
end

