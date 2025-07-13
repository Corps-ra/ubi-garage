ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Make sure all Vehicles are Stored on restart
MySQL.ready(function()
	if Config.Main.ParkVehicles then
		--ParkVehicles()
		
-- 		MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = true WHERE `stored` = @stored', {
-- 			['@stored'] = false
-- 		}, function(rowsChanged)
-- 			if rowsChanged > 0 then
-- 				print(('ubi-garage: %s vehicle(s) have been stored!'):format(rowsChanged))
-- 			end
-- 		end)
-- 		MySQL.Async.execute('UPDATE shared_vehicles SET `stored` = true WHERE `stored` = @stored', {
-- 			['@stored'] = false
-- 		}, function(rowsChanged)
-- 			if rowsChanged > 0 then
-- 				print(('ubi-garage: %s shared vehicle(s) have been stored!'):format(rowsChanged))
-- 			end
-- 		end)
		MySQL.Async.execute('UPDATE owned_vehicles SET `location` = @newLocation WHERE `location` = @location AND `job` = @job', {
			['@location'] = '',
			['@newLocation'] = 'apartmentGarage',
			['@job'] = 'civ'
		}, function(rowsChanged)
			if rowsChanged > 0 then
				print(('ubi-garage: %s vehicle(s) have been moved!'):format(rowsChanged))
			end
		end)
		
		MySQL.Async.execute('UPDATE shared_vehicles SET `location` = @newLocation WHERE `location` = @location', {
			['@location'] = '',
			['@newLocation'] = 'policeGarageMRPD'
		}, function(rowsChanged)
			if rowsChanged > 0 then
				print(('ubi-garage: %s shared vehicle(s) have been moved!'):format(rowsChanged))
			end
		end)
		MySQL.Async.execute('UPDATE owned_vehicles SET `location` = @newLocation WHERE `location` = @location AND `job` = @job', {
			['@location'] = '',
			['@newLocation'] = 'policeGarageMRPD',
			['@job'] = 'police'
		}, function(rowsChanged)
			if rowsChanged > 0 then
				print(('ubi-garage: %s vehicle(s) have been moved!'):format(rowsChanged))
			end
		end)
	else
		print('ubi-garage: Parking Vehicles on restart is currently set to false.')
	end
end)

-- Add Command for Getting Properties
if Config.Main.Commands then
	ESX.RegisterCommand('getgarages', 'user', function(xPlayer, args, showError)
		xPlayer.triggerEvent('ubi-garage:getPropertiesC')
	end, true, {help = 'Get Private Garages', validate = false})
end

-- Add Print Command for Getting Properties
RegisterServerEvent('ubi-garage:printGetProperties')
AddEventHandler('ubi-garage:printGetProperties', function()
	print('Getting Properties')
end)

-- Get Owned Properties
ESX.RegisterServerCallback('ubi-garage:getOwnedProperties', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local properties = {}

	MySQL.Async.fetchAll('SELECT * FROM owned_properties WHERE owner = @owner', {
		['@owner'] = xPlayer.identifier
	}, function(data)
		for _,v in pairs(data) do
			table.insert(properties, v.name)
		end
		cb(properties)
	end)
end)

ESX.RegisterServerCallback('ubi-garage:isVehicleOwned', function(source, cb, plate, location)
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(data)
		if data[1] ~= nil and location then
			MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored, `location` = @location WHERE plate = @plate', {
				['@stored'] = "in",
				['@plate'] = plate,
				['@location'] = location
			}, function(rowsChanged)
				if rowsChanged == 0 then
					
				end
				cb(true)
			end)
		else 
			cb(data)
		end
	end)
end)

ESX.RegisterServerCallback('ubi-garage:getAllOwnedVehicles', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local ownedCars = {}
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner', {
		['@owner'] = xPlayer.identifier,
		
	}, function(data)
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedCars, v)
		end
		cb(ownedCars)
	end)
		
end)

ESX.RegisterServerCallback('ubi-garage:getSharedVehicles', function(source, cb, job, type)

	if job == 'police' then
		if type == 'cars' then
			local sharedPoliceCars = {}
			MySQL.Async.fetchAll('SELECT * FROM shared_vehicles WHERE Type = @Type AND job = @job', {
				['@Type'] = 'car',
				['@job'] = 'police',
				['@category'] = 'cars'
			}, function(data)
				for _,v in pairs(data) do
					local vehicle = json.decode(v.vehicle)
					table.insert(sharedPoliceCars, {vehicle = vehicle, plate = v.plate, vehName = v.name, fuel = v.fuel, stored = v.stored})
				end
				cb(sharedPoliceCars)
			end)
		end
	end
	
end)

ESX.RegisterServerCallback('ubi-garage:vehicle', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', {
			['@owner']  =	xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)

ESX.RegisterServerCallback('ubi-garage:getOwnedVehiclesall', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored AND vehiclename = @vehiclename', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@vehiclename'] = vehiclename,
			['@job']    = 'civ',
			['@stored'] = stored,
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)


-- Start of Garage Fetch Vehicles
ESX.RegisterServerCallback('ubi-garage:getOwnedVehicles', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'A'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)

ESX.RegisterServerCallback('ubi-garage:ownedAmbulanceCars', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'ambulanceGarage'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)



ESX.RegisterServerCallback('ubi-garage:elginGarage', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'C'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)



ESX.RegisterServerCallback('ubi-garage:casinoGarage', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'B'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)



ESX.RegisterServerCallback('ubi-garage:bankGarage', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'E'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)

ESX.RegisterServerCallback('ubi-garage:kotGarag', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'D'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)


ESX.RegisterServerCallback('ubi-garage:sandyGarage', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'G'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)

ESX.RegisterServerCallback('ubi-garage:paletoGarage', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'H'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)

ESX.RegisterServerCallback('ubi-garage:impoundParking', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {owner = v.owner, vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'F'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {owner = v.owner, vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)

ESX.RegisterServerCallback('ubi-garage:policegarage', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND location = @location AND job = @job AND `stored` = @stored', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@stored'] = "in",
			['@location'] = location
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND location = @location AND Type = @Type AND job = @job', {
			['@owner']  = xPlayer.identifier,
			['@Type']   = 'car',
			['@job']    = 'civ',
			['@location'] = 'policeGarageMRPD'
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, location = v.location, fuel = v.fuel, plate = v.plate})
			end
			cb(ownedCars)
		end)
	end
end)





-- End of Impound Fetch Vehicles

-- Start of Impound Pay

ESX.RegisterServerCallback('ubi-garage:getOutOwnedCars', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND `stored` = @stored', {
		['@owner'] = xPlayer.identifier,
		['@Type']   = 'car',
		['@stored'] = 'out'
	}, function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedCars, vehicle)
		end
		cb(ownedCars)
	end)
end)


-- IMP bayar 
ESX.RegisterServerCallback('ubi-garage:storeVehicle', function (source, cb, vehicleProps)
	local ownedCars = {}
	local vehplate = vehicleProps.plate:match("^%s*(.-)%s*$")
	local vehiclemodel = vehicleProps.model
	local xPlayer = ESX.GetPlayerFromId(source)
	local vehiclePropsjson = json.encode(vehicleProps)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate ', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = vehicleProps.plate
	}, function (result)
		if result[1] ~= nil then
			local originalvehprops = json.decode(result[1].vehicle)
			if originalvehprops.model == vehiclemodel then
				MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle, job = @job WHERE owner = @owner AND plate = @plate', {
					['@owner'] = xPlayer.identifier,
					['@vehicle'] = vehiclePropsjson,
					['@plate'] = vehicleProps.plate,
					['job'] = 'civ'
				}, function (rowsChanged)
					if rowsChanged == 0 then
						print(('ubi-garage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
					end
					cb(true)
				end)
			else
				if Config.Main.KickCheaters then
					if Config.Main.CustomKickMsg then
						print(('ubi-garage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))

						-- DropPlayer(source, _U('custom_kick'))
						cb(false)
					else
						print(('ubi-garage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))

						-- DropPlayer(source, 'You have been Kicked from the Server for Possible Garage Cheating!!!')
						cb(false)
					end
				else
					print(('ubi-garage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))
					cb(false)
				end
			end
		else
			MySQL.Async.fetchAll('SELECT * FROM shared_vehicles WHERE plate = @plate', {
				['@plate'] = vehicleProps.plate
			}, function (result)
				if result[1] ~= nil then
					local originalvehprops = json.decode(result[1].vehicle)
					if originalvehprops.model == vehiclemodel then
						MySQL.Async.execute('UPDATE shared_vehicles SET vehicle = @vehicle WHERE plate = @plate', {
							['@plate'] = vehicleProps.plate,
							['@vehicle'] = json.encode(vehicleProps)
						}, function (rowsChanged)
							if rowsChanged == 0 then
								print(('ubi-garage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
							end
							cb(true)
						end)
					end
				else
					print(('made it here'):format(xPlayer.identifier))
					cb(false)
				end
			end)
		end
	end)
	
	

	
end)

ESX.RegisterServerCallback('ubi-garage:getname', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if Config.DontShowPoundCarsInGarage == true then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner', {
			['@owner']  = xPlayer.identifier,
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle})
			end
			cb(ownedCars)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner', {
			['@owner']  = xPlayer.identifier,
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle})
			end
			cb(ownedCars)
		end)
	end
end)

--[[
ESX.RegisterServerCallback('ubi-garage:storeVehicle', function (source, cb, vehicleProps)
	local ownedCars = {}
	local vehplate = vehicleProps.plate:match("^%s*(.-)%s*$")
	local vehiclemodel = vehicleProps.model
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = vehicleProps.plate
	}, function (result)
		if result[1] ~= nil then
			local originalvehprops = json.decode(result[1].vehicle)
			if originalvehprops.model == vehiclemodel then
				MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle WHERE owner = @owner AND plate = @plate', {
					['@owner'] = xPlayer.identifier,
					['@vehicle'] = json.encode(vehicleProps),
					['@plate'] = vehicleProps.plate
				}, function (rowsChanged)
					if rowsChanged == 0 then
						print(('ubi-garage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
					end
					cb(true)
				end)
			else
				if Config.Main.KickCheaters then
					if Config.Main.CustomKickMsg then
						print(('ubi-garage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))

						DropPlayer(source, _U('custom_kick'))
						cb(false)
					else
						print(('ubi-garage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))

						DropPlayer(source, 'You have been Kicked from the Server for Possible Garage Cheating!!!')
						cb(false)
					end
				else
					print(('ubi-garage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))
					cb(false)
				end
			end
		else
			print(('ubi-garage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
			cb(false)
		end
	end)
	
	MySQL.Async.fetchAll('SELECT * FROM shared_vehicles WHERE plate = @plate', {
		['@plate'] = vehicleProps.plate
	}, function (result)
		if result[1] ~= nil then
			local originalvehprops = json.decode(result[1].vehicle)
			if originalvehprops.model == vehiclemodel then
				MySQL.Async.execute('UPDATE shared_vehicles SET vehicle = @vehicle WHERE plate = @plate', {
					['@plate'] = vehicleProps.plate
				}, function (rowsChanged)
					if rowsChanged == 0 then
						print(('ubi-garage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
					end
					cb(true)
				end)
			end
		else
			print(('ubi-garage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
			cb(false)
		end
	end)
	cb(false)

	
end)
--]]

-- Pay to Return Broken Vehicles
RegisterServerEvent('ubi-garage:payhealth')
AddEventHandler('ubi-garage:payhealth', function(price)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(price)
	TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. price)

	if Config.Main.GiveSocMoney then
		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			account.addMoney(price)
		end)
	end
end)

-- Rename Vehicle
RegisterServerEvent('ubi-garage:renameVehicle')
AddEventHandler('ubi-garage:renameVehicle', function(plate, name)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET name = @name WHERE plate = @plate', {
		['@name'] = name,
		['@plate'] = plate
	}, function(rowsChanged)
		if rowsChanged == 0 then
			print(('ubi-garage: %s exploited the garage!'):format(xPlayer.identifier))
		end
	end)
end)



-- Modify State of Vehicles
RegisterServerEvent('ubi-garage:setVehicleState')
AddEventHandler('ubi-garage:setVehicleState', function(plate, state, location, vehicleProps)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored, `location` = @location WHERE plate = @plate', {
		['@stored'] = state,
		['@plate'] = plate,
		['@location'] = location,
	}, function(rowsChanged)
		if rowsChanged == 0 then
			MySQL.Async.execute('UPDATE shared_vehicles SET `stored` = @stored, `location` = @location WHERE plate = @plate', {
				['@stored'] = state,
				['@plate'] = plate,
				['@location'] = location,
			}, function(rowsChanged)
				if rowsChanged == 0 then
					print(('ubi-garage: %s exploited the garage!'):format(xPlayer.identifier))
				end
			end)
		end
	end)
end)

RegisterServerEvent('ubi-garage:setVehiclin')
AddEventHandler('ubi-garage:setVehiclin', function()
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored', {
		['@stored'] = 'in',
		['@location'] = location
	}, function(rowsChanged)
		if rowsChanged == 0 then
			MySQL.Async.execute('UPDATE shared_vehicles SET `stored` = @stored', {
				['@stored'] = 'in',
			}, function(rowsChanged)
				if rowsChanged == 0 then
					print(('ubi-garage: %s exploited the garage!'):format(xPlayer.identifier))
				end
			end)
		end
	end)
end)

RegisterServerEvent('admin:svcar')
AddEventHandler('admin:svcar', function(vehicleProps, fuel, plate, modelveh)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, stored, type, job, fuel) VALUES (@owner, @plate, @vehicle, @stored, @type, @job, @fuel)', {
		['@owner']   = xPlayer.identifier,
		['@plate']   = plate,
		['@vehicle'] = json.encode(vehicleProps),
		['@stored'] = "out",
		['@type'] = "car",
		['@job'] = "civ",
		['@fuel'] = fuel
	}, function (rowsChanged)
	end)
end)



RegisterServerEvent('ubi-garage:setVehicleout')
AddEventHandler('ubi-garage:setVehicleout', function(plate, state, location)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate', {
		['@stored'] = state,
		['@plate'] = plate,
	}, function(rowsChanged)
		if rowsChanged == 0 then
			MySQL.Async.execute('UPDATE shared_vehicles SET `stored` = @stored WHERE plate = @plate', {
				['@stored'] = state,
				['@plate'] = plate,
			}, function(rowsChanged)
				if rowsChanged == 0 then
					print(('ubi-garage: %s exploited the garage!'):format(xPlayer.identifier))
				end
			end)
		end
	end)
end)


RegisterServerEvent('ubi-garage:setVehiclename')
AddEventHandler('ubi-garage:setVehiclename', function(plate, vehiclename)
	local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.execute('UPDATE owned_vehicles SET vehiclename = @vehiclename WHERE plate = @plate', {
		['@vehiclename'] = vehiclename,
		['@plate'] = plate,
	}, function(rowsChanged)
		if rowsChanged == 0 then
			MySQL.Async.execute('UPDATE shared_vehicles SET vehiclename = @vehiclename WHERE plate = @plate ', {
				['@vehiclename'] = vehiclename,
				['@plate'] = plate,
			}, function(rowsChanged)
				if rowsChanged == 0 then
					print(('ubi-garage: %s exploited the garage!'):format(xPlayer.identifier))
				end
			end)
		end
	end)
end)

-- set vehicle model
RegisterServerEvent('ubi-garage:setvehmodel')
AddEventHandler('ubi-garage:setvehmodel', function(modelveh, plate)
local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.execute('UPDATE owned_vehicles SET modelveh = @modelveh WHERE plate = @plate', {
		['@modelveh'] = modelveh,
		['@plate'] = plate,
	}, function(rowsChanged)
		if rowsChanged == 0 then
			MySQL.Async.execute('UPDATE shared_vehicles SET modelveh = @modelveh WHERE plate = @plate ', {
				['@modelveh'] = modelveh,
				['@plate'] = plate,
			}, function(rowsChanged)
				if rowsChanged == 0 then
					print(('ubi-garage: %s exploited the garage!'):format(xPlayer.identifier))
				end
			end)
		end
	end)
end)


-- Set Fuel Level
RegisterServerEvent('ubi-garage:setVehicleFuel')
AddEventHandler('ubi-garage:setVehicleFuel', function(plate, fuel)
	local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.execute('UPDATE owned_vehicles SET fuel = @fuel WHERE plate = @plate', {
		['@fuel'] = fuel,
		['@plate'] = plate,
	}, function(rowsChanged)
		if rowsChanged == 0 then
			MySQL.Async.execute('UPDATE shared_vehicles SET fuel = @fuel WHERE plate = @plate ', {
				['@fuel'] = fuel,
				['@plate'] = plate,
			}, function(rowsChanged)
				if rowsChanged == 0 then
					print(('ubi-garage: %s exploited the garage!'):format(xPlayer.identifier))
				end
			end)
		end
	end)
end)
