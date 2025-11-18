local function SendDiscordEmbed(msg)
    if not SV_Config.DiscordLogging then return end
    if not SV_Config.DiscordWebHook or SV_Config.DiscordWebHook == "" then
      print("bl-electric] Error: No valid Discord Webhook URL configured!")
      return
    end
  
    local embed = {
      {
        ["color"] = 3066993, -- Blue (Use valid RGB integer values)
        ["title"] = "bl-electric",
        ["author"] = {
          ["name"] = "bl-electric",
          ["icon_url"] = "https://files.fivemerr.com/images/60736d99-3091-41f6-af89-42e0c624ebf6.png",
        },
        ["description"] = tostring(msg),               -- Ensure it's a string
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ") -- Proper ISO timestamp for Discord
      }
    }
  
    local payload = json.encode({ embeds = embed })
  
    PerformHttpRequest(SV_Config.DiscordWebHook, function(err, text, headers)
      if err ~= 204 then -- 204 = No Content (Success)
        print("[bl-electric] Discord Webhook Error: " .. tostring(err) .. " | Response: " .. tostring(text))
      end
    end, 'POST', payload, { ["Content-Type"] = "application/json" })
  end






local function SendConsoleAlert(eventName, plrId, faildDist)
    print(
      '\n^8[CHEATING-ALERT]^7 ' .. eventName .. ' Distance Check Failed!',
      '\n^8[CHEATING-ALERT]^7 Player Name: ' .. GetPlayerName(plrId),
      '\n^8[CHEATING-ALERT]^7 ' .. GetPlayerIdentifierByType(plrId, 'license'),
      '\n^8[CHEATING-ALERT]^7 Over Vaild Distance By ' .. faildDist .. ' units!'
    )
end

RegisterNetEvent('bl-electric:server:Reward', function()
    local src = source
    local pay = math.random(Config.Reward[1], Config.Reward[2])
    exports.qbx_core:AddMoney(src, 'bank', pay, 'Pay Check')
    SendDiscordEmbed("Player `")
end)

RegisterNetEvent('bl-electric:server:GiveReturnMoney', function()
    local src = source
    local dist = #(GetEntityCoords(GetPlayerPed(src)).xyz - Config.PedSpawn.xyz)


    if dist > 22.0 then
        SendConsoleAlert('bl-electric:server:GiveReturnMoney', src, dist - 5.0)
        return
    end
    local pay = Config.VehRent
    exports.qbx_core:AddMoney(src, 'bank', pay, 'Returning truck rental money')
end)

local function takeMoney(src, amount, reason)
    if exports.qbx_core:GetMoney(src, 'cash') >= amount then

        exports.qbx_core:RemoveMoney(src, 'cash', amount, reason)
        return true
    
    elseif exports.qbx_core:GetMoney(src, 'bank') >= amount then
        exports.qbx_core:RemoveMoney(src, 'bank', amount, reason)

        return true
    else
        return false
    end
end


lib.callback.register('bl-electric:server:VehRent', function(source)
    local src = source
    local rent = Config.VehRent
    return takeMoney(src, rent, 'Renting Work Truck')
end)

