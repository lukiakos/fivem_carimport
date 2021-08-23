ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local frakciopenz = nil


ESX.RegisterServerCallback('sacra_carimport:automentes', function(source, cb, rendeles, generatedPlates)
    local xPlayer = ESX.GetPlayerFromId(source)
    local currentPlate = nil
    for x,y in pairs(rendeles) do
        for var=1,y do
            currentPlate = generatedPlates[var]
            MySQL.Async.execute('INSERT INTO owned_vehicles (owner, state, plate, vehicle) VALUES (@owner, @state, @plate, @vehicle)', {
                ['@owner'] = xPlayer.identifier,
                ['@state'] = 1,
                ['@plate'] = currentPlate,
                ['@vehicle'] = json.encode({model = GetHashKey(x), plate = currentPlate})
            }, function(keszenvan)
                xPlayer.showNotification('A garazsadban van tuzi', false, true)
                cb(true)
                end)
            end
        for var=1,y do
            table.remove(generatedPlates, 1)
        end
    end

end)

ESX.RegisterServerCallback('sacra_carimport:frakciopenzlevonas', function(source, cb, osszeg)
	local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchScalar("SELECT `money` FROM `addon_account_data` WHERE `account_name` = 'society_sacra'", {}, function(result)
        if result >= osszeg then
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_sacra', function(account)
                account.removeMoney(osszeg)
            end)
            xPlayer.showNotification('Rendelés kifizetve a vállalkozási számláról', true, false)
            cb(true)
        else
            xPlayer.showNotification('Nincs elég pénzed erre', true, false)
            cb(false)
        end
    end)
end)

ESX.RegisterServerCallback('sacra_carimport:autoMentes', function(source, cb, rendeles)


end)


ESX.RegisterServerCallback('sacra_carimport:isPlateTaken', function(source, cb, plate)
	MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)
		cb(result[1] ~= nil)
	end)
end)