ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('sacra_carimport:importMegkezd', function(source, cb, model, plate, modelPrice)
	local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= modelPrice then
        xPlayer.removeMoney(modelPrice)
        print(modelPrice)

        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
		    ['@owner']   = xPlayer.identifier,
		    ['@plate']   = plate,
		    ['@vehicle'] = json.encode({model = GetHashKey(model), plate = plate})
	    }, function(rowsChanged)
		    xPlayer.showNotification("Autó megrendelve")
		    cb(true)
            end)
    else
        xPlayer.showNotification("Nincs elég pénzed erre")
        cb(false)
    end
end)

ESX.RegisterServerCallback('sacra_carimport:isPlateTaken', function(source, cb, plate)
	MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)
		cb(result[1] ~= nil)
	end)
end)