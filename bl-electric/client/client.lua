local WaterPedName = Config.WaterPed
local clipboard
local workTruck
local currentDestination
local currentZone
local destinationBlip
local dutyStatus = false

local returnTruck = false

local function SpawnWaterPed()
    while not HasModelLoaded(WaterPedName) do
        Citizen.Wait(0)
        RequestModel(WaterPedName)
    end
    while not HasModelLoaded('p_amb_clipboard_01') do
        Citizen.Wait(0)
        RequestModel('p_amb_clipboard_01')
    end
    while not HasAnimDictLoaded("missfam4") do
        Citizen.Wait(0)
        RequestAnimDict("missfam4")
    end
    WaterPed = CreatePed(1, Config.WaterPed, Config.PedSpawn.x, Config.PedSpawn.y, Config.PedSpawn.z - 1, Config.PedSpawn.w, false, false)
    FreezeEntityPosition(WaterPed, true)
    SetEntityInvincible(WaterPed, true)
    SetBlockingOfNonTemporaryEvents(WaterPed, true)
    local clipboardProp = 'p_amb_clipboard_01'
    clipboard = CreateObject(clipboardProp, Config.PedSpawn.x, Config.PedSpawn.y, Config.PedSpawn.z, false, false, false)
    TaskPlayAnim(WaterPed, "missfam4", "base", 2.0, 2.0, 50000000, 51, 0, false, false, false)
    AttachEntityToEntity(clipboard, WaterPed, GetPedBoneIndex(WaterPed, 36029), 0.16, 0.08, 0.1, -130.0, -50.0, 0.0, true, true, false, true, 1, true)
end


local function DutyStatus(toState)
    dutyStatus = toState

    local dutyString = ''

    if dutyStatus then dutyString = 'on' else dutyString = 'off' end
    lib.notify({
        title = 'Electrical Job',
        description = 'You went ' .. dutyString .. ' duty.',
        type = 'success'
    })

end

local function EndJob()
    RemoveBlip(destinationBlip)
    exports.ox_target:removeZone(currentZone)
    DutyStatus(false)

    if returnTruck == true then
        TriggerServerEvent('bl-electric:server:GiveReturnMoney')
        DeleteEntity(workTruck)
        returnTruck = false
    end


end

local function RentVehicle()
    local maxVehAttempts = 10
    local vehAttempts = 0
    local closestVeh

    repeat
        closestVeh = GetClosestVehicle(Config.WorkTruckSpawn.x, Config.WorkTruckSpawn.y, Config.WorkTruckSpawn.z, 5.0, 0, 70)
        vehAttempts = vehAttempts + 1
        if closestVeh ~= 0 then
            lib.notify({
                title = 'Electric Manager',
                description = 'Vehicle In Area',
                type = 'error',
            })

            return false                                                 -- Stop execution completely
        end
        Wait(1)
    until vehAttempts == maxVehAttempts

    -- if closestVeh ~= 0 then
    --     return     -- Stop execution completely
    -- end

    if not lib.callback.await('bl-electric:server:VehRent', false) then
        
        lib.notify({
            title = 'Electric Job Manager',
            description = 'You dont enought money to rent the vehicle.',
            type = 'error',
            duration = 5000,
            showDuration = true
        })

        return false
    end

    while not HasModelLoaded(Config.WorkTruck) do
        Citizen.Wait(0)
        RequestModel(Config.WorkTruck)
      end

    local workTruckModel = Config.WorkTruck
    workTruck = CreateVehicle(workTruckModel, Config.WorkTruckSpawn.x, Config.WorkTruckSpawn.y, Config.WorkTruckSpawn.z, Config.WorkTruckSpawn.w, true, false)
    SetEntityAsMissionEntity(workTruck, true, true)
    SetPedIntoVehicle(PlayerPedId(), workTruck, -1)


    TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(workTruck))

      local plrPed = PlayerPedId()

    Citizen.CreateThread(function()
        while true do
            Wait(10)
            local plrCoords = GetEntityCoords(plrPed)


            local inReturn = #(plrCoords.xy - Config.WorkTruckSpawn.xy)
            if inReturn < 10.0 then
                if GetVehiclePedIsIn(plrPed, false) == workTruck then
                    if not lib.isTextUIOpen() then
                        lib.showTextUI('[E] - Return Vehicle')
                    end
                    if IsControlPressed(0, 38) then
                        lib.hideTextUI()
                        returnTruck = true
                        EndJob()
                        break
                    end
                else
                    lib.hideTextUI()
                end
            else
                lib.hideTextUI()
            end
        end
    end)

end


local function GetWork()

    local ply = PlayerPedId()

    local randomLoc = math.random(1, #Config.WorkLocs)
    currentDestination = Config.WorkLocs[randomLoc]



    if currentZone then
        exports.ox_target:removeZone(currentZone)
        
    end

    destinationBlip = AddBlipForCoord(currentDestination.x, currentDestination.y, currentDestination.z)


    currentZone =exports.ox_target:addSphereZone({
        coords = vec3(currentDestination.x, currentDestination.y, currentDestination.z + 1),
        name = 'power_box_zone',
        radius = 0.7,
        rotation = 150,
        debug = true,

        options = {{
            distance = 1.5,
            label = 'Power Box',
            icon = 'fas fa-bolt',

        onSelect = function ()
            local plyCoords = GetEntityCoords(ply)

            if not DoesEntityExist(workTruck) then
                lib.notify({title = "Job", description = "Your work truck is not detected!", type = "error"})
                return
            end
        
        
            local truckCoords = GetEntityCoords(workTruck)
            local distance = #(plyCoords - truckCoords)
            print(truckCoords)
            print(plyCoords)
        
            if distance > 10.0 then
                lib.notify({title = "Job", description = "You need to be closer to your work truck!", type = "error"})
                return
            end


            RemoveBlip(destinationBlip)
            TaskStartScenarioInPlace(ply, "WORLD_HUMAN_WELDING", 0, true)
            local success = exports["ez_electricminigame"]:WiringFix(50) -- 30seconds countdown
            if success == true then
                print('penis')
                ClearPedTasksImmediately(ply)
                TriggerServerEvent('bl-electric:server:Reward')
                GetWork()

            else
                ClearPedTasksImmediately(ply)
                SetPedToRagdoll(ply, 5000, 1000, 0)
            end
        end
        }}
    })
   

    --SetEntityCoords(ply, currentDestination.x, currentDestination.y, currentDestination.z + 1, true, true, true, true)
    

    SetBlipSprite(destinationBlip, 1)
    SetBlipColour(destinationBlip, 5)
    SetBlipRoute(destinationBlip, true)
end


local function StartJob()
    if RentVehicle() == false then
        return
    end

    DutyStatus(true)
    GetWork()
end




Citizen.CreateThread(function ()
    SpawnWaterPed()
    for _, value in ipairs(Config.Blips) do
       local blip = AddBlipForCoord(value.coords.x, value.coords.y, value.coords.z)
        SetBlipSprite(blip, value.sprite)
        SetBlipColour(blip, value.color)
        SetBlipScale(blip, value.size)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(value.name)
        EndTextCommandSetBlipName(blip)
    end

    exports.ox_target:addLocalEntity(WaterPed, {
        {
            distance = 1.5,
            name = 'waterped',
            label = 'Water & Power Manager',
            icon = "fas fa-bolt-lightning",

            onSelect = function ()
                exports.dialog:OpenDialog(WaterPed, Config.Interaction)
            end
        }
    })
end)


RegisterNetEvent('bl-electric:client:StartJob', function()
    if dutyStatus then EndJob() else StartJob() end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    DeleteEntity(WaterPed)
    DeleteEntity(clipboard)
    DeleteEntity(workTruck)

    --SetEntityCoords(PlayerPedId(), 727.16, 133.09, 80.96, true, true, true, true)
end)

RegisterCommand('penise', function()
    TriggerServerEvent('bl-electric:server:GiveReturnMoney')
end, false)