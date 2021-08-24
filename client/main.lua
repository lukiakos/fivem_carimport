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
local vegosszeg = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local osszeg2 = 0
local vegleges = false
local melo = nil
local munkalekerve = false
local gradelekerve = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
    ped = PlayerPedId()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer   
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

Citizen.CreateThread(function() -- Eldöntjük, hogy a játékos elég közel van-e a rendelő CP-hez (configban átírható)
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        Citizen.Wait(500)
        if Vdist(coords, Config.RendeloCPLoc) < 5 then
            kozeli = true
        else
            kozeli = false
        end
    end
end)

Citizen.CreateThread(function() -- Rendelő panel felirat megjelenítése ha a player Sacra Car leader vagy Al-Leader
    local rendelocp = Config.RendeloCPLoc -- Configban átírható a rendelő cp helye
    local sacranev = Config.SacraNev -- Configban átírható a szerveren használt sacra job nevére
    while true do
        Citizen.Wait(4)
        if kozeli then -- Ha elég közel van, és leader vagy alleader, akkor jelenik meg a felirat, illetve akkor tudja megnyitni a panelt
            if not munkalekerve then sacragetJob() end
            if not gradelekerve then sacragetGrade() end
            if frakcio == sacranev then
                if frakgrade == 3 or frakgrade == 4 then
                    Draw3DText(rendelocp.x, rendelocp.y, rendelocp.z, "Nyomj ~y~[E]~w~-t a panel megjelenítéséhez.", 0.4)
                    if Vdist(GetEntityCoords(PlayerPedId()), Config.RendeloCPLoc) < 1 and IsControlJustReleased(1, 38) and not menunyitva then
                        ESX.UI.Menu.CloseAll()
                        RendeloMenu()
                    end
                end
            end
        end
    end
end)

function sacragetGrade()
    gradelekerve = true
    ESX.TriggerServerCallback('sacra_carimport:getGrade', function(grade)
        frakgrade = grade
    end)
end

function sacragetJob()
    munkalekerve = true
    ESX.TriggerServerCallback('sacra_carimport:getJob', function(melo)
        frakcio = melo
    end)
end

function RendeloMenu()
    menunyitva = true
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'autorendelo1', {
        title    = "Autóimport panel",
        align    = "left",
        elements = autok
    }, function(data, menu)
        menu.close()
        menunyitva = false
        if not kamionlerakva and not vegleges then
            local carid = data.current.carid
            local value = data.current.value
            MenuValasztott(carid,value,rendeles)
        end
        if kamionlerakva then
            ESX.ShowNotification('Már lekérted a kamiont.', true, true)
        end
        if vegleges then
            ESX.ShowNotification('Már véglegesítetted a rendelést', true, true)
        end
    end,
    function(data, menu)
        menu.close()
        menunyitva = false
    end)
end

function Veglegesit(carid,value,rendeles)
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'veglegsito', {
        title = 'Véglegesíted a rendelést?',
        align = "left",
        elements = igenmenu
    }, function(data, menu)
        menu.close()
        menunyitva = false
        if data.current.value == 'igen' then
            vegleges = true
            osszegSzamolo(carid)
            ESX.ShowNotification('Ennyit kell fizetned: ' .. '~g~' .. osszeg)
            if not hasCreatedMarkers then
                CreateMarkers(result,value,rendeles)
            end
        end
        if data.current.value == 'nem' then
            vegleges = false
            RendeloMenu()
        end
    end,
    function(data, menu)
        menu.close()
        menunyitva = false
    end)
end

function MenuValasztott(carid,value,rendeles)
    megrendelve = true
    DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 30)
        while (UpdateOnscreenKeyboard() == 0) do
            DisableAllControlActions(0);
            Wait(0);
        end
    if (GetOnscreenKeyboardResult()) then
        local result = GetOnscreenKeyboardResult()
        rendeles[value] = result
        Veglegesit(carid,value,rendeles)
    end
end

function osszegSzamolo(carid)
    for v,k in pairs(rendeles) do
        for x,y in pairs(autok) do
            if y.value == v then
                local autoar = y.price * k
                table.remove(vegosszeg,tonumber(y.carid))
                table.insert(vegosszeg,tonumber(y.carid),autoar)
            end
        end
    end
    for p,d in pairs(vegosszeg) do
        osszeg = osszeg + d
    end
end


function CreateMarkers(result,value,rendeles)
    hasCreatedMarkers = true
    rendelesleadva = true
    local ped = PlayerPedId()
    local felvevo = Config.FelvevoHely
    local felvevoblip = AddBlipForCoord(felvevo.x,felvevo.y,felvevo.z)
    SetBlipRoute(felvevoblip, true)
    local sacranev = Config.SacraNev
    while megrendelve do
        local coords = GetEntityCoords(ped)
        local tavolsag = Vdist(coords, felvevo)
        Citizen.Wait(4)
        if frakcio == sacranev then
            local felvevomarker = DrawMarker(1,felvevo.x,felvevo.y,felvevo.z - 1,0.0,0.0,0.0,0.0,180,0.0,5.0,5.0,5.0,0,255,0,200,false,false,2,false,nil,nil,false)
            if tavolsag < 20 then
                Draw3DText(felvevo.x,felvevo.y,felvevo.z + 0.5, 'Nyomj ~y~[E]~w~-t a rendelés kamionra pakolásához', 0.4)
                if tavolsag < 2.5 then
                    SetBlipRoute(felvevoblip, false)
                    ESX.ShowHelpNotification('Nyomj ~y~[E]~w~-t a rendelés kamionra pakolásához', true, false)
                    if IsControlJustReleased(1, 38) and vegleges then
                        RemoveBlip(felvevoblip)
                        Fizet(osszeg,result,value,rendeles)
                    end
                    if not vegleges then
                        ESX.ShowNotification('Nem véglegesítetted a rendelést', true, true)
                    end
                end
            end
        end
    end
end

RegisterCommand('heading', function()
    print(GetEntityHeading(ped))
end,false)

function Fizet(osszeg,result,value,rendeles)
    ESX.TriggerServerCallback('sacra_carimport:frakciopenzlevonas', function(success)
        if success then
            megrendelve = false
            generatedPlates = {}
            for k,v in pairs(rendeles) do
                for var=1,v do
                    local ideiglenesplate = GeneratePlate()
                    table.insert(generatedPlates, ideiglenesplate)
                end
            end
            ESX.ShowNotification('~g~Szállj be a kamionba, és szállítsd el az autókat a Sacra Car autókereskedéshez!', true, true)
            KamionLerak()
        else
            megrendelve = true
        end
    end, osszeg)
end

function KamionLerak()
    local trspawn = Config.TrailerSpawnPoint
    local kamspawn = Config.KamionSpawnPoint

    RequestModel('tr4') 
    while not HasModelLoaded('tr4') do
        Citizen.Wait(10)
    end
    ideiglenestrailer = CreateVehicle('tr4',trspawn.x,trspawn.y,trspawn.z,75.10,true,false)
    SetModelAsNoLongerNeeded('tr4')
    SetVehicleNumberPlateText(ideiglenestrailer, 'SACRA' .. GetRandomNumber(3))

    RequestModel('packer') 
    while not HasModelLoaded('packer') do
        Citizen.Wait(10)
    end
    ideigleneskamion = CreateVehicle('packer',kamspawn.x,kamspawn.y,kamspawn.z,207.87,true,false)
    SetModelAsNoLongerNeeded('packer')
    SetVehicleNumberPlateText(ideigleneskamion, 'SACRA' .. GetRandomNumber(3))
    SetVehicleFuelLevel(ideigleneskamion, 60.0)
    SetVehicleColours(ideigleneskamion,28,28)

    szallitasalatt = true
    kamionlerakva = true
    Leszallit()
end

function Leszallit()
    local leado = Config.LeszallitoCP
    local leadoblip = AddBlipForCoord(leado.x,leado.y,leado.z)
    SetBlipRoute(leadoblip,true)
    while szallitasalatt do
        local coords = GetEntityCoords(ped)
        local tavolsag = Vdist(coords, leado)
        Citizen.Wait(2)
        if frakcio == sacranev then
            local leadomarker = DrawMarker(1,leado.x,leado.y,leado.z - 1,0.0,0.0,0.0,0.0,180,0.0,5.0,5.0,5.0,0,255,0,200,false,false,2,false,nil,nil,false)
            if tavolsag < 20 then
                Draw3DText(leado.x,leado.y,leado.z + 0.5, 'Nyomj ~y~[E]~w~-t, hogy leszállítsd az autókat.', 0.4)
                if tavolsag < 2.5 then
                    if IsControlJustReleased(1, 38) then
                        SetBlipRoute(leadoblip, false)
                        RemoveBlip(leadoblip)
                        Tarolas()
                    end
                end
            end
        end
    end
end

function Tarolas()
    if IsPedSittingInVehicle(ped, ideigleneskamion) then
        ESX.Game.DeleteVehicle(ideigleneskamion)
        ESX.Game.DeleteVehicle(ideiglenestrailer)

        ESX.TriggerServerCallback('sacra_carimport:automentes', function(success)
            if success then
                ESX.ShowNotification('~g~Sikeres ~w~importálás. Az autókat megtalálhatod a garázsodban.', true, true)
            else
                ESX.ShowNotification('~r~Valami hiba történt!', true, true)
            end
        end, rendeles, generatedPlates)
        kamionlerakva = false
        hasCreatedMarkers = false
        osszeg = 0
        vegleges = false
        szallitasalatt = false
    else
        ESX.ShowNotification('~r~A lekért kamionban kell ülnöd!', true, true)
        szallitasalatt = true
    end
end

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