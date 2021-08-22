ESX              = nil
local PlayerData = {}
local kozeli = false
local hasznalhat = false
local menunyitva = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
  Citizen.Wait(10000)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

Citizen.CreateThread(function() -- Rendelő panel felirat megjelenítése ha a player Sacra Car leader vagy Al-Leader
    local rendelocp = Config.RendeloCPLoc
    local sacranev = Config.SacraNev -- Configban átírható a szerveren használt sacra job nevére
    while true do
        Citizen.Wait(2)
        if ESX.PlayerData.job.name == sacranev and ESX.PlayerData.job.grade == 4 then
            hasznalhat = true
        elseif ESX.PlayerData.job.name == sacranev and ESX.PlayerData.job.grade == 3 then
            hasznalhat = true
        end
        if kozeli and hasznalhat then
            Draw3DText(rendelocp.x, rendelocp.y, rendelocp.z, "Nyomj ~y~[E]~w~-t a panel megjelenítéséhez.", 0.4)
            if Vdist(GetEntityCoords(PlayerPedId()), Config.RendeloCPLoc) < 1 and IsControlJustReleased(1, 38) and not menunyitva then
                ESX.UI.Menu.CloseAll()
                RendeloMenu()
            end
        end
    end
end)

function RendeloMenu()
    menunyitva = true
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'autorendelo1', {
        title    = "Autóimport panel",
        align    = "left",
        elements = autok
    }, function(data, menu)
        menu.close()
        menunyitva = false
        if data.current.value == 'blista' then
            local carid = 1
            SpawnAuto('blista', carid)
            print('anyad')
            print(autok[carid].price)
        end
        if data.current.value == 'adder' then
            local carid = 2
            SpawnAuto('adder', carid)
        end
        if data.current.value == 'anyad' then
            print('Anyad picsajat')
        end
    end, 
    function(data, menu)
        menu.close()
        menunyitva = false
    end)
end

function SpawnAuto(autonev, carid)
    local lerakohely = Config.LerakoHely
    print(lerakohely)
    local generatedPlate = GeneratePlate()
    print(generatedPlate)
    local modelPrice = autok[carid].price
    print(modelPrice)
    ESX.TriggerServerCallback('sacra_carimport:importMegkezd', function(success)
        if success then
            print("tesztest")
            ESX.Game.SpawnVehicle(autonev, lerakohely, GetEntityHeading(), function(vehicle)
                print("sdklzhgweghto")
                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                SetVehicleNumberPlateText(vehicle, generatedPlate)
                SetVehicleFuelLevel(vehicle, 60.0)
                print(GetVehicleFuelLevel(vehicle))
                menunyitva = false
            end)
        end
    end, autonev, generatedPlate, modelPrice)
end




Citizen.CreateThread(function() -- Eldöntjük, hogy a játékos elég közel van-e a CP-hez (configban átírható)
    local ped = PlayerPedId()
    while true do
        local coords = GetEntityCoords(ped)
        Citizen.Wait(500)
        if Vdist(coords, Config.RendeloCPLoc) < 5 then
            kozeli = true
        else
            kozeli = false
        end
    end
end)


  
local NumberCharset = {}
local Charset = {}

for i = 48, 57 do table.insert(NumberCharset, string.char(i)) end
for i = 65, 90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

function GeneratePlate()
	local generatedPlate
	local doBreak = false

	while true do
		Citizen.Wait(2)
		math.randomseed(GetGameTimer())
		if Config.Main.PlateUseSpace then
			generatedPlate = string.upper(GetRandomLetter(Config.Main.PlateLetters) .. ' ' .. GetRandomNumber(Config.Main.PlateNumbers))
		else
			generatedPlate = string.upper(GetRandomLetter(Config.Main.PlateLetters) .. GetRandomNumber(Config.Main.PlateNumbers))
		end

		ESX.TriggerServerCallback('sacra_carimport:isPlateTaken', function (isPlateTaken)
			if not isPlateTaken then
				doBreak = true
			end
		end, generatedPlate)

		if doBreak then
			break
		end
	end

	return generatedPlate
end

-- mixing async with sync tasks
function IsPlateTaken(plate)
	local callback = 'waiting'

	ESX.TriggerServerCallback('sacra_carimport:isPlateTaken', function(isPlateTaken)
		callback = isPlateTaken
	end, plate)

	while type(callback) == 'string' do
		Citizen.Wait(0)
	end

	return callback
end

function GetRandomNumber(length)
	Citizen.Wait(0)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

function GetRandomLetter(length)
	Citizen.Wait(0)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end

function Draw3DText(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x,y,z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(true)
    SetTextColour(255,255,255,215)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 300
    DrawRect(_x, _y + 0.0150, 0.06 + factor, 0.03, 41, 11, 41, 100)
end