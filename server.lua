ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent("es:addGroup", "mod", "user", function(group) end)

-- Modify if you want, btw the _admin_ needs to be able to target the group and it will work
local groupsRequired = {
	slay = "mod",
	noclip = "admin",
	crash = "superadmin",
	freeze = "mod",
	bring = "mod",
	["goto"] = "mod",
	slap = "mod",
	slay = "mod",
	kick = "mod",
	ban = "admin",
	screenshot = "mod",
	spectate = "mod"
}

local banned = ""
local bannedTable = {}

function loadBans()
	banned = LoadResourceFile(GetCurrentResourceName(), "bans.json") or ""
	if banned ~= "" then
		bannedTable = json.decode(banned)
	else
		bannedTable = {}
	end
end

RegisterCommand("refresh_bans", function()
	loadBans()
end, true)

function loadExistingPlayers()
	TriggerEvent("es:getPlayers", function(curPlayers)
		for k,v in pairs(curPlayers)do
			TriggerClientEvent("orp:admin:setGroup", v.get('source'), v.get('group'))
		end
	end)
end

loadExistingPlayers()

function removeBan(id)
	bannedTable[id] = nil
	SaveResourceFile(GetCurrentResourceName(), "bans.json", json.encode(bannedTable), -1)
end

function isBanned(id)
	if bannedTable[id] ~= nil then
		if bannedTable[id].expire < os.time() then
			if bannedTable[id].expire ~= -1 then
				removeBan(id)
				return false
			elseif bannedTable[id].expire == -1 then
				return bannedTable[id] 
			end
		else
			return bannedTable[id]
		end
	else
		return false
	end
end

function permBanUser(bannedBy, id)
	bannedTable[id] = {
		banner = bannedBy,
		reason = "Permanently banned from this server",
		expire = -1
	}

	SaveResourceFile(GetCurrentResourceName(), "bans.json", json.encode(bannedTable), -1)
end

function banUser(expireSeconds, bannedBy, id, re)
	bannedTable[id] = {
		banner = bannedBy,
		reason = re,
		expire = (os.time() + expireSeconds)
	}

	SaveResourceFile(GetCurrentResourceName(), "bans.json", json.encode(bannedTable), -1)
end

RegisterCommand('printidentifiers', function(source, args)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() ~= 'user' then
		if args[1] then
			source = args[1]
		else
			source = source
		end

		local identifiers = {
			steam = GetPlayerIdentifiers(source)[1],
			license = GetPlayerIdentifiers(source)[2],
			xbl = GetPlayerIdentifiers(source)[3],
			live = GetPlayerIdentifiers(source)[4],
			discord = GetPlayerIdentifiers(source)[5]
		}
		local name = GetPlayerName(source)
		print(json.encode(identifiers))
		local report = {
			{
				["color"] = color,
				["title"] = "**The Player ".. name .."'s Identifiers have been printed**",
				["description"] = identifiers.steam.. "\n\n"..identifiers.license.."\n\n"..identifiers.xbl.."\n\n"..identifiers.live.."\n\n"..identifiers.discord,
				["footer"] = {
					["text"] = "Made By Known",
				},
			}
		}
		PerformHttpRequest(Config.Kickwebhook, function(err, text, headers) end, 'POST', json.encode({username = name, embeds = report}), { ['Content-Type'] = 'application/json' })
	end
end)

--! For New Kick System

RegisterNetEvent('orp:admin:kick')
AddEventHandler('orp:admin:kick', function(user, msg, name)

	local playerHex = GetPlayerIdentifier(source)

	DropPlayer(user, msg)

	local report = {
		{
			["color"] = color,
			["title"] = "**The Player ".. name .." Has Been Kicked**",
			["description"] = "Kick Reason: **"..msg.."\n\nSteam Hex: "..playerHex.."**",
			["footer"] = {
				["text"] = "Made By Known",
			},
		}
	}
	PerformHttpRequest(Config.Kickwebhook, function(err, text, headers) end, 'POST', json.encode({username = name, embeds = report}), { ['Content-Type'] = 'application/json' })
end)

-- ! For New Banning System

RegisterNetEvent('dropplayer')
AddEventHandler('dropplayer', function(reason, user, time)

	local msg = "Ban Reason: "..reason.."\nTime Remaninng: "..(os.date("%c", os.time() + time))

	DropPlayer(user, msg)

end)

RegisterNetEvent('orp:admin:ban')
AddEventHandler('orp:admin:ban', function(name, reason, user, time)

	local playerHex = GetPlayerIdentifier(source)

	if time == "-1" then

		time = 29999999999.0

		banUser(time, name, playerHex, reason)

	else

		time = time * 85999

		banUser(time, name, playerHex, reason)

		TriggerEvent('dropplayer', reason, user, time)

	end

	local banexpire = (os.date("%c", os.time() + time))

	local report = {
		{
			["color"] = color,
			["title"] = "**The Player ".. user .." Has Been Banned**",
			["description"] = "Ban Reason: "..reason.."\n\nBan Expire: "..banexpire.."\n\nSteam: "..playerHex,
			["footer"] = {
				["text"] = "Made By Known",
			},
		}
	}
	PerformHttpRequest(Config.Banwebhook, function(err, text, headers) end, 'POST', json.encode({username = user, embeds = report}), { ['Content-Type'] = 'application/json' })

end)

AddEventHandler('playerConnecting', function(user, set)
	for k,v in ipairs(GetPlayerIdentifiers(source))do
		local banData = isBanned(v)
		if banData ~= false then
			set("🛑Banned for: " .. banData.reason .. "\n🕐Expires at : " .. (os.date("%c", banData.expire)))
			CancelEvent()
		end
	end
end)

AddEventHandler('es:incorrectAmountOfArguments', function(source, wantedArguments, passedArguments, user, command)
	if(source == 0)then
		print("Argument count mismatch (passed " .. passedArguments .. ", wanted " .. wantedArguments .. ")")
	else
		TriggerClientEvent('chat:addMessage', source, {
			args = {"^1SYSTEM", "Incorrect amount of arguments! (" .. passedArguments .. " passed, " .. requiredArguments .. " wanted)"}
		})
	end
end)

RegisterNetEvent('orp:admin:spectate')
AddEventHandler('orp:admin:spectate', function(name, user)

	local target = user

	TriggerClientEvent('es_camera:spectate', target)
	
	TriggerClientEvent('es_camera:spectate', target)
end)


RegisterServerEvent('orp:admin:quick')
AddEventHandler('orp:admin:quick', function(id, type)
	local Source = source
	TriggerEvent('es:getPlayerFromId', source, function(user)
		TriggerEvent('es:getPlayerFromId', id, function(target)
			TriggerEvent('es:canGroupTarget', user.getGroup(), groupsRequired[type], function(available)
				TriggerEvent('es:canGroupTarget', user.getGroup(), target.getGroup(), function(canTarget)
					if canTarget and available then
						if type == "freeze" then TriggerClientEvent('orp:admin:quick', id, type) end
						if type == "bring" then TriggerClientEvent('orp:admin:quick', id, type, Source) end
						if type == "goto" then TriggerClientEvent('orp:admin:quick', Source, type, id) end
						if type == "screenshot" then
							local identifier1 = GetPlayerIdentifiers(id)[1]
							local identifier2 = GetPlayerIdentifiers(id)[2]
							local identifier3 = GetPlayerIdentifiers(id)[3]
							local identifier4 = GetPlayerIdentifiers(id)[4]
							local identifier5 = GetPlayerIdentifiers(id)[5]
							local screenshotOptions = {
								encoding = 'png',
								quality = 1
							}    
							exports['discord-screenshot']:requestCustomClientScreenshotUploadToDiscord(id, Config.Screenshotwebhook, screenshotOptions, {
								username = 'orp:admin',
								avatar_url = '',
								content = '',
								embeds = {
									{
										color = 16711680,
										author = {
											name = 'orp:admin',
											icon_url = ''
										},
										title = 'Screenshot of player '..GetPlayerName(id).."\n\n"..identifier1.."\n\n"..identifier2.."\n\n"..identifier3.."\n\n"..identifier4.."\n\n"..identifier5,
										
										footer = {
											text = "____________________\n\n[" .. os.date("%Y/%m/%d %X") .. "]\n\nMade By Known For Oasis RP",
										}
									}
								}
							});
						end
						if type == "spectate" then
							TriggerClientEvent('es_camera:onSpectate', -1, source)
							TriggerClientEvent('es_camera:spectate', source, id)
						end

						if type == "ban" then
							local id
							local ip
							for k,v in ipairs(GetPlayerIdentifiers(source))do
								if string.sub(v, 1, string.len("steam:")) == "steam:" then
									permBanUser(user.identifier, v)
								elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
									permBanUser(user.identifier, v)
								end
							end

							DropPlayer(id, GetConvar("orp:admin_banreason", "You were banned from this server"))
						end
					else
						if not available then
							TriggerClientEvent('chat:addMessage', Source, {
								args = {"^1SYSTEM", "You do not have permission to do this"}
							})
						else
							TriggerClientEvent('chat:addMessage', Source, {
								args = {"^1SYSTEM", "You do not have permission to do this"}
							})
						end
					end
				end)
			end)
		end)
	end)
end)

AddEventHandler('es:playerLoaded', function(Source, user)
	TriggerClientEvent('orp:admin:setGroup', Source, user.getGroup())
end)

RegisterServerEvent('orp:admin:set')
AddEventHandler('orp:admin:set', function(t, USER, GROUP)
	local Source = source
	TriggerEvent('es:getPlayerFromId', source, function(user)
		TriggerEvent('es:canGroupTarget', user.getGroup(), "admin", function(available)
			if available then
			if t == "group" then
				if(GetPlayerName(USER) == nil)then
					TriggerClientEvent('chat:addMessage', source, {
						args = {"^1SYSTEM", "Player not found"}
					})
				else
					TriggerEvent("es:getAllGroups", function(groups)
						if(groups[GROUP])then
							TriggerEvent("es:setPlayerData", USER, "group", GROUP, function(response, success)
								TriggerClientEvent('orp:admin:setGroup', USER, GROUP)
								TriggerClientEvent('chat:addMessage', -1, {
									args = {"^1CONSOLE", "Group of ^2^*" .. GetPlayerName(tonumber(USER)) .. "^r^0 has been set to ^2^*" .. GROUP}
								})
							end)
						else
							TriggerClientEvent('chat:addMessage', Source, {
								args = {"^1SYSTEM", "Group not found"}
							})
						end
					end)
				end
			elseif t == "level" then
				if(GetPlayerName(USER) == nil)then
					TriggerClientEvent('chat:addMessage', Source, {
						args = {"^1SYSTEM", "Player not found"}
					})
				else
					GROUP = tonumber(GROUP)
					if(GROUP ~= nil and GROUP > -1)then
						TriggerEvent("es:setPlayerData", USER, "permission_level", GROUP, function(response, success)
							if(true)then
								TriggerClientEvent('chat:addMessage', -1, {
									args = {"^1CONSOLE", "Permission level of ^2" .. GetPlayerName(tonumber(USER)) .. "^0 has been set to ^2 " .. tostring(GROUP)}
								})
							end
						end)

						TriggerClientEvent('chat:addMessage', Source, {
							args = {"^1SYSTEM", "Permission level of ^2" .. GetPlayerName(tonumber(USER)) .. "^0 has been set to ^2 " .. tostring(GROUP)}
						})
					else
						TriggerClientEvent('chat:addMessage', Source, {
							args = {"^1SYSTEM", "Invalid integer entered"}
						})
					end
				end
			elseif t == "money" then
				if(GetPlayerName(USER) == nil)then
					TriggerClientEvent('chat:addMessage', Source, {
						args = {"^1SYSTEM", "Player not found"}
					})
				else
					GROUP = tonumber(GROUP)
					if(GROUP ~= nil and GROUP > -1)then
						TriggerEvent('es:getPlayerFromId', USER, function(target)
							target.setMoney(GROUP)
						end)
					else
						TriggerClientEvent('chat:addMessage', Source, {
							args = {"^1SYSTEM", "Invalid integer entered"}
						})
					end
				end
			elseif t == "bank" then
				if(GetPlayerName(USER) == nil)then
					TriggerClientEvent('chat:addMessage', Source, {
						args = {"^1SYSTEM", "Player not found"}
					})
				else
					GROUP = tonumber(GROUP)
					if(GROUP ~= nil and GROUP > -1)then
						TriggerEvent('es:getPlayerFromId', USER, function(target)
							target.setBankBalance(GROUP)
						end)
					else
						TriggerClientEvent('chat:addMessage', Source, {
							args = {"^1SYSTEM", "Invalid integer entered"}
						})
					end
				end
			end
			else
				TriggerClientEvent('chat:addMessage', Source, {
					args = {"^1SYSTEM", "Superadmin required to do this"}
				})
			end
		end)
	end)
end)

RegisterCommand('setadmin', function(source, args, raw)
	local player = tonumber(args[1])
	local level = tonumber(args[2])
	if args[1] then
		if (player and GetPlayerName(player)) then
			if level then
				TriggerEvent("es:setPlayerData", tonumber(args[1]), "permission_level", tonumber(args[2]), function(response, success)
					RconPrint(response)
		
					TriggerClientEvent('es:setPlayerDecorator', tonumber(args[1]), 'rank', tonumber(args[2]), true)
					TriggerClientEvent('chat:addMessage', -1, {
						args = {"^1CONSOLE", "Permission level of ^2" .. GetPlayerName(tonumber(args[1])) .. "^0 has been set to ^2 " .. args[2]}
					})
				end)
			else
				RconPrint("Invalid integer\n")
			end
		else
			RconPrint("Player not ingame\n")
		end
	else
		RconPrint("Usage: setadmin [user-id] [permission-level]\n")
	end
end, true)

RegisterCommand('setgroup', function(source, args, raw)
	local player = tonumber(args[1])
	local group = args[2]
	if args[1] then
		if (player and GetPlayerName(player)) then
			TriggerEvent("es:getAllGroups", function(groups)

				if(groups[args[2]])then
					TriggerEvent("es:getPlayerFromId", player, function(user)
						ExecuteCommand('remove_principal identifier.' .. user.getIdentifier() .. " group." .. user.getGroup())

						TriggerEvent("es:setPlayerData", player, "group", args[2], function(response, success)
							TriggerClientEvent('es:setPlayerDecorator', player, 'group', tonumber(group), true)
							TriggerClientEvent('chat:addMessage', -1, {
								args = {"^1CONSOLE", "Group of ^2^*" .. GetPlayerName(player) .. "^r^0 has been set to ^2^*" .. group}
							})

							ExecuteCommand('add_principal identifier.' .. user.getIdentifier() .. " group." .. user.getGroup())
						end)
					end)
				else
					RconPrint("This group does not exist.\n")
				end
			end)
		else
			RconPrint("Player not ingame\n")
		end
	else
		RconPrint("Usage: setgroup [user-id] [group]\n")
	end
end, true)

RegisterNetEvent('orp:admin:AdminPlayerList')
AddEventHandler('orp:admin:AdminPlayerList',function()
	local xPlayers = ESX.GetPlayers()
	for i = 1, #xPlayers, 1 do
		local thePlayer = GetPlayerName(xPlayers[i])
		TriggerClientEvent('orp:admin:AdminPlayerList',source, thePlayer,xPlayers[i])
	end
end)

RegisterCommand('setmoney', function(source, args, raw)
	local player = tonumber(args[1])
	local money = tonumber(args[2])
	if args[1] then
		if (player and GetPlayerName(player)) then
			if money then
				TriggerEvent("es:getPlayerFromId", player, function(user)
					if(user)then
						user.setMoney(money)

						RconPrint("Money set")
						TriggerClientEvent('chat:addMessage', player, {
							args = {"^1SYSTEM", "Your money has been set to: ^2^*$" .. money}
						})
					end
				end)
			else
				RconPrint("Invalid integer\n")
			end
		else
			RconPrint("Player not ingame\n")
		end
	else
		RconPrint("Usage: setmoney [user-id] [money]\n")
	end
end, true)

-- Default commands
TriggerEvent('es:addCommand', 'admin', function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, {
		args = {"^1SYSTEM", "Level: ^*^2 " .. tostring(user.get('permission_level'))}
	})
	TriggerClientEvent('chat:addMessage', source, {
		args = {"^1SYSTEM", "Group: ^*^2 " .. user.getGroup()}
	})
end, {help = "Shows what admin level you are and what group you're in"})

-- Ban a person
TriggerEvent("es:addGroupCommand", 'ban', "admin", function(source, args, user)
	local Source = source
	if args[1] then
		if(tonumber(args[1]) and GetPlayerName(tonumber(args[1])))then
			local player = tonumber(args[1])

			-- User permission check
			TriggerEvent("es:getPlayerFromId", player, function(target)
				TriggerEvent('es:canGroupTarget', user.getGroup(), target.getGroup(), function(canTarget)
					if canTarget then
						local reason = args
						table.remove(reason, 1)
						local time = args[1]
						table.remove(reason, 1)
						if(#reason == 0)then
							reason = "You have been banned from the server"
						else
							reason = "" .. table.concat(reason, " ")
						end

						-- Awful shit logic but eh, it works?
						-- Days
						if string.find(time, "m")then
							time = math.floor(time:gsub("%m", "") * 60)
						elseif string.find(time, "h") then
							time = math.floor(time:gsub("%h", "") * 60 * 60)
						elseif string.find(time, "d") then
							time = math.floor(time:gsub("%d", "") * 60 * 60 * 24)
						elseif string.find(time, "y") then
							time = math.floor(time:gsub("%y", "") * 60 * 60 * 24 * 365)
						end

						TriggerClientEvent('chat:addMessage', -1, {
							args = {"^1SYSTEM", "Player ^2" .. GetPlayerName(player) .. "^0 has been kicked(^2" .. reason .. "^0)"}
						})
						banUser(time, user.getIdentifier(), target.getIdentifier(), reason)
						DropPlayer(player, "Banned for: " .. reason .. "\nExpires: " .. (os.date("%c", os.time() + time)))
					else
						TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "You can not target this person"}})
					end
				end)
			end)
		else
			TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
		end
	else
		TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
	end
end)

-- Report to admins
TriggerEvent('es:addCommand', 'report', function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, {
		args = {"^1REPORT", " (^2" .. GetPlayerName(source) .. " | " .. source .. "^0) " .. table.concat(args, " ")}
	})

	TriggerEvent("es:getPlayers", function(pl)
		for k,v in pairs(pl) do
			TriggerEvent("es:getPlayerFromId", k, function(user)
				if(user.getPermissions() > 0 and k ~= source)then
					TriggerClientEvent('chat:addMessage', k, {
						args = {"^1REPORT", " (^2" .. GetPlayerName(source) .." | "..source.."^0) " .. table.concat(args, " ")}
					})
				end
			end)
		end
	end)
end, {help = "Report a player or an issue", params = {{name = "report", help = "What you want to report"}}})

-- Noclip
TriggerEvent('es:addGroupCommand', 'noclip', "admin", function(source, args, user)
	TriggerClientEvent("orp:admin:noclip", source)
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Insufficienct permissions!"} })
end, {help = "Enable or disable noclip"})

-- Kicking
TriggerEvent('es:addGroupCommand', 'kick', "mod", function(source, args, user)
	if args[1] then
		if(tonumber(args[1]) and GetPlayerName(tonumber(args[1])))then
			local player = tonumber(args[1])

			-- User permission check
			TriggerEvent("es:getPlayerFromId", player, function(target)

				local reason = args
				table.remove(reason, 1)
				if(#reason == 0)then
					reason = "Kicked: You have been kicked from the server"
				else
					reason = "Kicked: " .. table.concat(reason, " ")
				end

				TriggerClientEvent('chat:addMessage', -1, {
					args = {"^1SYSTEM", "Player ^2" .. GetPlayerName(player) .. "^0 has been kicked(^2" .. reason .. "^0)"}
				})
				DropPlayer(player, reason)
			end)
		else
			TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
		end
	else
		TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Insufficienct permissions!"} })
end, {help = "Kick a user with the specified reason or no reason", params = {{name = "userid", help = "The ID of the player"}, {name = "reason", help = "The reason as to why you kick this player"}}})

-- Announcing
TriggerEvent('es:addGroupCommand', 'announce', "admin", function(source, args, user)
	TriggerClientEvent('chat:addMessage', -1, {
		args = {"^1ANNOUNCEMENT", table.concat(args, " ")}
	})
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Insufficienct permissions!"} })
end, {help = "Announce a message to the entire server", params = {{name = "announcement", help = "The message to announce"}}})

-- Freezing
local frozen = {}
TriggerEvent('es:addGroupCommand', 'freeze', "mod", function(source, args, user)
	if args[1] then
		if(tonumber(args[1]) and GetPlayerName(tonumber(args[1])))then
			local player = tonumber(args[1])

			-- User permission check
			TriggerEvent("es:getPlayerFromId", player, function(target)

				if(frozen[player])then
					frozen[player] = false
				else
					frozen[player] = true
				end

				TriggerClientEvent('orp:admin:freezePlayer', player, frozen[player])

				local state = "unfrozen"
				if(frozen[player])then
					state = "frozen"
				end

				TriggerClientEvent('chat:addMessage', player, { args = {"^1SYSTEM", "You have been " .. state .. " by ^2" .. GetPlayerName(source)} })
				TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Player ^2" .. GetPlayerName(player) .. "^0 has been " .. state} })
			end)
		else
			TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
		end
	else
		TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Insufficienct permissions!"} })
end, {help = "Freeze or unfreeze a user", params = {{name = "userid", help = "The ID of the player"}}})

-- Bring
TriggerEvent('es:addGroupCommand', 'bring', "mod", function(source, args, user)
	if args[1] then
		if(tonumber(args[1]) and GetPlayerName(tonumber(args[1])))then
			local player = tonumber(args[1])

			-- User permission check
			TriggerEvent("es:getPlayerFromId", player, function(target)

				TriggerClientEvent('orp:admin:teleportUser', target.get('source'), user.getCoords().x, user.getCoords().y, user.getCoords().z)

				TriggerClientEvent('chat:addMessage', player, { args = {"^1SYSTEM", "You have brought by ^2" .. GetPlayerName(source)} })
				TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Player ^2" .. GetPlayerName(player) .. "^0 has been brought"} })
			end)
		else
			TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
		end
	else
		TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Insufficienct permissions!"} })
end, {help = "Teleport a user to you", params = {{name = "userid", help = "The ID of the player"}}})

-- Slap
TriggerEvent('es:addGroupCommand', 'slap', "admin", function(source, args, user)
	if args[1] then
		if(tonumber(args[1]) and GetPlayerName(tonumber(args[1])))then
			local player = tonumber(args[1])

			-- User permission check
			TriggerEvent("es:getPlayerFromId", player, function(target)

				TriggerClientEvent('orp:admin:slap', player)

				TriggerClientEvent('chat:addMessage', player, { args = {"^1SYSTEM", "You have slapped by ^2" .. GetPlayerName(source)} })
				TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Player ^2" .. GetPlayerName(player) .. "^0 has been slapped"} })
			end)
		else
			TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
		end
	else
		TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Insufficienct permissions!"} })
end, {help = "Slap a user", params = {{name = "userid", help = "The ID of the player"}}})

-- Goto
TriggerEvent('es:addGroupCommand', 'goto', "mod", function(source, args, user)
	if args[1] then
		if(tonumber(args[1]) and GetPlayerName(tonumber(args[1])))then
			local player = tonumber(args[1])

			-- User permission check
			TriggerEvent("es:getPlayerFromId", player, function(target)
				if(target)then

					TriggerClientEvent('orp:admin:teleportUser', source, target.getCoords().x, target.getCoords().y, target.getCoords().z)

					TriggerClientEvent('chat:addMessage', player, { args = {"^1SYSTEM", "You have been teleported to by ^2" .. GetPlayerName(source)} })
					TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Teleported to player ^2" .. GetPlayerName(player) .. ""} })
				end
			end)
		else
			TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
		end
	else
		TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Insufficienct permissions!"} })
end, {help = "Teleport to a user", params = {{name = "userid", help = "The ID of the player"}}})

-- Kill yourself
TriggerEvent('es:addCommand', 'die', function(source, args, user)
	TriggerClientEvent('orp:admin:kill', source)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "You killed yourself"} })
end, {help = "Suicide"})

-- Slay a player
TriggerEvent('es:addGroupCommand', 'slay', "admin", function(source, args, user)
	if args[1] then
		if(tonumber(args[1]) and GetPlayerName(tonumber(args[1])))then
			local player = tonumber(args[1])

			-- User permission check
			TriggerEvent("es:getPlayerFromId", player, function(target)

				TriggerClientEvent('orp:admin:kill', player)

				TriggerClientEvent('chat:addMessage', player, { args = {"^1SYSTEM", "You have been killed by ^2" .. GetPlayerName(source)} })
				TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Player ^2" .. GetPlayerName(player) .. "^0 has been killed."} })
			end)
		else
			TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
		end
	else
		TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Insufficienct permissions!"} })
end, {help = "Slay a user", params = {{name = "userid", help = "The ID of the player"}}})

-- Crashing
TriggerEvent('es:addGroupCommand', 'crash', "superadmin", function(source, args, user)
	if args[1] then
		if(tonumber(args[1]) and GetPlayerName(tonumber(args[1])))then
			local player = tonumber(args[1])

			-- User permission check
			TriggerEvent("es:getPlayerFromId", player, function(target)

				TriggerClientEvent('orp:admin:crash', player)

				TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Player ^2" .. GetPlayerName(player) .. "^0 has been crashed."} })
			end)
		else
			TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
		end
	else
		TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Incorrect player ID"}})
	end
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = {"^1SYSTEM", "Insufficienct permissions!"} })
end, {help = "Crash a user, no idea why this still exists", params = {{name = "userid", help = "The ID of the player"}}})

function stringsplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

loadBans()



-- Anticheat
RegisterNetEvent('orp:admin:blcar')
AddEventHandler('orp:admin:blcar', function(name, reason)

	local playerHex = GetPlayerIdentifier(source)

	local report = {
		{
			["color"] = color,
			["title"] = "**The Player ".. name .." Has Spawned A Blacklisted Vehicle**",
			["description"] = "Car Spawn Code: "..reason.."\n\nSteam: "..playerHex,
			["footer"] = {
				["text"] = "Made By Known",
			},
		}
	}
	PerformHttpRequest(Config.Blcarwebhook, function(err, text, headers) end, 'POST', json.encode({username = user, embeds = report}), { ['Content-Type'] = 'application/json' })

end)

RegisterNetEvent('orp:admin:blweapon')
AddEventHandler('orp:admin:blweapon', function(name, reason)

	local playerHex = GetPlayerIdentifier(source)

	local report = {
		{
			["color"] = color,
			["title"] = "**The Player ".. name .." Has A Blacklisted Weapon**",
			["description"] = "Weapon Code: "..reason.."\n\nSteam: "..playerHex,
			["footer"] = {
				["text"] = "Made By Known",
			},
		}
	}
	PerformHttpRequest(Config.Blweaponwebhook, function(err, text, headers) end, 'POST', json.encode({username = user, embeds = report}), { ['Content-Type'] = 'application/json' })

end)
