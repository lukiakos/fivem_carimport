ESX              = nil
local PlayerData = {}
local kozeli = false
local hasznalhat = false
local menunyitva = false
local megrendelve = false
local szallitasalatt = false
local rendelesleadva = false
local sacranev = Config.SacraNev
local rendeles = {}
local hasCreatedMarkers = false
local kamionlerakva = false
local generatedPlates = {}
local osszeg = 0
local autoar = 0
local vegosszeg = {}

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
    local rendelocp = Config.RendeloCPLoc -- Configban átírható a rendelő cp helye
    local sacranev = Config.SacraNev -- Configban átírható a szerveren használt sacra job nevére
    while true do
        Citizen.Wait(2)
        if ESX.PlayerData.job.name == sacranev and ESX.PlayerData.job.grade == 4 then
            hasznalhat = true
        elseif ESX.PlayerData.job.name == sacranev and ESX.PlayerData.job.grade == 3 then
            hasznalhat = true
        end
        if kozeli and hasznalhat then -- Ha elég közel van, és leader vagy alleader, akkor jelenik meg a felirat, illetve akkor tudja megnyitni a panelt
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
        if data.current.value == 'blista' and not kamionlerakva then
            local carid = 1
            local value = data.current.value
            MenuValasztott(carid,value)
        end
        if data.current.value == 'adder' and not kamionlerakva then
            local carid = 2
            local value = data.current.value
            MenuValasztott(carid,value)
        end
        if data.current.value == 'voltic' and not kamionlerakva then
            local carid = 3
            local value = data.current.value
            MenuValasztott(carid,value)
        end
        if data.current.value == 'phoenix' and not kamionlerakva then
            local carid = 4
            local value = data.current.value
            MenuValasztott(carid,value)
        end
        if kamionlerakva then
            ESX.ShowNotification('Már lekérted a kamiont.', true, true)
        end
    end,
    function(data, menu)
        menu.close()
        menunyitva = false
    end)
end

function MenuValasztott(carid,value)
    megrendelve = true
    DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 30)
        while (UpdateOnscreenKeyboard() == 0) do
            DisableAllControlActions(0);
            Wait(0);
        end
    if (GetOnscreenKeyboardResult()) then
        local result = GetOnscreenKeyboardResult()
        rendeles[value] = result
        osszeg = osszeg + (autok[carid].price * result)
        osszegSzamolo(osszeg,carid,value,result)
        ESX.ShowNotification('Eddig ennyit kell fizetned' .. osszeg)
        if not hasCreatedMarkers then
            CreateMarkers(result,value,rendeles)
        end
    end
end

function osszegSzamolo(osszeg,carid,value,result)
    for v,k in pairs(rendeles) do
        for x,y in pairs(autok) do
            if y.value == v then
                autoar = y.price * k
                table.remove(vegosszeg, carid)
                table.insert(vegosszeg,tonumber(carid),autoar)
                print(vegosszeg[1])
                for z,q in pairs(vegosszeg) do
                    print(z,q)
                end
            end
        end
    end
end



function CreateMarkers(result,value,rendeles)
    hasCreatedMarkers = true
    rendelesleadva = true
    local felvevo = Config.FelvevoHely
    local ped = PlayerPedId()
    local sacranev = Config.SacraNev
    while megrendelve do
        local coords = GetEntityCoords(ped)
        local tavolsag = Vdist(coords, felvevo)
        Citizen.Wait(4)
        if ESX.PlayerData.job.name == sacranev then
            local felvevomarker = DrawMarker(1,felvevo.x,felvevo.y,felvevo.z - 1,0.0,0.0,0.0,0.0,180,0.0,5.0,5.0,5.0,0,255,0,200,false,false,2,false,nil,nil,false)
            if tavolsag < 20 then
                Draw3DText(felvevo.x,felvevo.y,felvevo.z + 0.5, 'Nyomj ~y~[E]~w~-t a rendelés kamionra pakolásához', 0.4)
                if tavolsag < 2.5 then
                    ESX.ShowHelpNotification('Nyomj ~y~[E]~w~-t a rendelés kamionra pakolásához', true, false)
                    if IsControlJustReleased(1, 38) then
                        Fizet(osszeg,result,value,rendeles)
                        KamionLerak()
                        megrendelve = false
                    end
                end
            end
        end
    end
end

function Fizet(osszeg,result,value,rendeles)
    print('jheltgwetui')
    ESX.TriggerServerCallback('sacra_carimport:frakciopenzlevonas', function(success)
        if success then
            print('asndwrfh')
            generatedPlates = {}
            for k,v in pairs(rendeles) do
                print(k, v)
                for var=1,v do
                    local ideiglenesplate = GeneratePlate()
                    print(ideiglenesplate)
                    table.insert(generatedPlates, ideiglenesplate)
                end
            end
            for k,v in pairs(generatedPlates) do
                print(k, v)
            end
        end
    end, osszeg)
end

function KamionLerak()
    ESX.Game.SpawnVehicle('tr4', Config.TrailerSpawnPoint, GetEntityHeading(), function(vehicle)
        SetVehicleNumberPlateText(vehicle, 'SACRA' .. GetRandomNumber(3))
    end)
    ESX.Game.SpawnVehicle('packer', Config.KamionSpawnPoint, GetEntityHeading(), function(vehicle)
        SetVehicleNumberPlateText(vehicle, 'SACRA' .. GetRandomNumber(3))
        SetVehicleFuelLevel(vehicle, 60.0)
    end)
    szallitasalatt = true
    kamionlerakva = true
    Leszallit()
end

function Leszallit()
    local leado = Config.LeszallitoCP
    local ped = PlayerPedId()
    while szallitasalatt do
        local coords = GetEntityCoords(ped)
        local tavolsag = Vdist(coords, leado)
        Citizen.Wait(2)
        if ESX.PlayerData.job.name == sacranev then
            local leadomarker = DrawMarker(1,leado.x,leado.y,leado.z - 1,0.0,0.0,0.0,0.0,180,0.0,5.0,5.0,5.0,0,255,0,200,false,false,2,false,nil,nil,false)
            if tavolsag < 20 then
                print('Helo')
                Draw3DText(leado.x,leado.y,leado.z + 0.5, 'Nyomj ~y~[E]~w~-t, hogy leszállítsd az autókat.', 0.4)
                if tavolsag < 2.5 then
                    if IsControlJustReleased(1, 38) then
                        print('kurva')
                        Tarolas()
                        szallitasalatt = false
                    end
                end
            end
        end
    end
end

function Tarolas()
    local ped = PlayerPedId()
    ESX.Game.DeleteVehicle(GetVehiclePedIsIn(ped,false))

    ESX.TriggerServerCallback('sacra_carimport:automentes', function(success)
        if success then
            ESX.ShowNotification('~g~Sikeres ~w~importálás. Az autókat megtalálhatod a garázsodban.', true, true)
        else
            ESX.ShowNotification('~r~Valami hiba történt!', true, true)
        end
    end, rendeles, generatedPlates)
    kamionlerakva = false
    hasCreatedMarkers = false
end



Citizen.CreateThread(function() -- Eldöntjük, hogy a játékos elég közel van-e a rendelő CP-hez (configban átírható)
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