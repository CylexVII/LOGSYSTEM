AddEventHandler('es:playerLoaded', function(source, _player)
	local _source = source
	local tasks   = {}

	local userData = {
		accounts     = {},
		inventory    = {},
		job          = {},
		loadout      = {},
		playerName   = GetPlayerName(_source),
		lastPosition = nil
	}

	TriggerEvent('es:getPlayerFromId', _source, function(player)
		-- Update user name in DB
		table.insert(tasks, function(cb)
			MySQL.Async.execute('UPDATE `users` SET `name` = @name WHERE `identifier` = @identifier', {
				['@identifier'] = player.getIdentifier(),
				['@name'] = userData.playerName
			}, function(rowsChanged)
				cb()
			end)
		end)

		-- Get accounts
		table.insert(tasks, function(cb)
			MySQL.Async.fetchAll('SELECT * FROM `user_accounts` WHERE `identifier` = @identifier', {
				['@identifier'] = player.getIdentifier()
			}, function(accounts)
				for i=1, #Config.Accounts, 1 do
					for j=1, #accounts, 1 do
						if accounts[j].name == Config.Accounts[i] then
							table.insert(userData.accounts, {
								name  = accounts[j].name,
								money = accounts[j].money,
								label = Config.AccountLabels[accounts[j].name]
							})
							break
						end
					end
				end

				cb()
			end)
		end)

		-- Get inventory
		table.insert(tasks, function(cb)

			MySQL.Async.fetchAll('SELECT * FROM `user_inventory` WHERE `identifier` = @identifier', {
				['@identifier'] = player.getIdentifier()
			}, function(inventory)
				local tasks2 = {}

				for i=1, #inventory do
					local item = ESX.Items[inventory[i].item]

					if item then
						table.insert(userData.inventory, {
							name = inventory[i].item,
							count = inventory[i].count,
							label = item.label,
							limit = item.limit,
							usable = ESX.UsableItemsCallbacks[inventory[i].item] ~= nil,
							rare = item.rare,
							canRemove = item.canRemove
						})
					else
						print(('es_extended: invalid item "%s" ignored!'):format(inventory[i].item))
					end
				end

				for k,v in pairs(ESX.Items) do
					local found = false

					for j=1, #userData.inventory do
						if userData.inventory[j].name == k then
							found = true
							break
						end
					end

					if not found then
						table.insert(userData.inventory, {
							name = k,
							count = 0,
							label = ESX.Items[k].label,
							limit = ESX.Items[k].limit,
							usable = ESX.UsableItemsCallbacks[k] ~= nil,
							rare = ESX.Items[k].rare,
							canRemove = ESX.Items[k].canRemove
						})

						local scope = function(item, identifier)
							table.insert(tasks2, function(cb2)
								MySQL.Async.execute('INSERT INTO user_inventory (identifier, item, count) VALUES (@identifier, @item, @count)', {
									['@identifier'] = identifier,
									['@item'] = item,
									['@count'] = 0
								}, function(rowsChanged)
									cb2()
								end)
							end)
						end

						scope(k, player.getIdentifier())
					end

				end

				Async.parallelLimit(tasks2, 5, function(results) end)

				table.sort(userData.inventory, function(a,b)
					return a.label < b.label
				end)

				cb()
			end)

		end)

		-- Get job and loadout
		table.insert(tasks, function(cb)

			local tasks2 = {}

			-- Get job name, grade and last position
			table.insert(tasks2, function(cb2)

				MySQL.Async.fetchAll('SELECT job, job_grade, loadout, position FROM `users` WHERE `identifier` = @identifier', {
					['@identifier'] = player.getIdentifier()
				}, function(result)
					local job, grade = result[1].job, tostring(result[1].job_grade)

					if ESX.DoesJobExist(job, grade) then
						local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

						userData.job = {}

						userData.job.id    = jobObject.id
						userData.job.name  = jobObject.name
						userData.job.label = jobObject.label

						userData.job.grade        = tonumber(grade)
						userData.job.grade_name   = gradeObject.name
						userData.job.grade_label  = gradeObject.label
						userData.job.grade_salary = gradeObject.salary

						userData.job.skin_male    = {}
						userData.job.skin_female  = {}

						if gradeObject.skin_male ~= nil then
							userData.job.skin_male = json.decode(gradeObject.skin_male)
						end
			
						if gradeObject.skin_female ~= nil then
							userData.job.skin_female = json.decode(gradeObject.skin_female)
						end
					else
						print(('es_extended: %s had an unknown job [job: %s, grade: %s], setting as unemployed!'):format(player.getIdentifier(), job, grade))

						local job, grade = 'unemployed', '0'
						local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

						userData.job = {}

						userData.job.id    = jobObject.id
						userData.job.name  = jobObject.name
						userData.job.label = jobObject.label
			
						userData.job.grade        = tonumber(grade)
						userData.job.grade_name   = gradeObject.name
						userData.job.grade_label  = gradeObject.label
						userData.job.grade_salary = gradeObject.salary
			
						userData.job.skin_male    = {}
						userData.job.skin_female  = {}
					end

					if result[1].loadout ~= nil then
						userData.loadout = json.decode(result[1].loadout)

						-- Compatibility with old loadouts prior to components update
						for k,v in ipairs(userData.loadout) do
							if v.components == nil then
								v.components = {}
							end
						end
					end

					if result[1].position ~= nil then
						userData.lastPosition = json.decode(result[1].position)
					end

					cb2()
				end)

			end)

			Async.series(tasks2, cb)

		end)

		-- Run Tasks
		Async.parallel(tasks, function(results)
			local xPlayer = CreateExtendedPlayer(player, userData.accounts, userData.inventory, userData.job, userData.loadout, userData.playerName, userData.lastPosition)

			xPlayer.getMissingAccounts(function(missingAccounts)
				if #missingAccounts > 0 then

					for i=1, #missingAccounts, 1 do
						table.insert(xPlayer.accounts, {
							name  = missingAccounts[i],
							money = 0,
							label = Config.AccountLabels[missingAccounts[i]]
						})
					end

					xPlayer.createAccounts(missingAccounts)
				end

				ESX.Players[_source] = xPlayer

				TriggerEvent('esx:playerLoaded', _source, xPlayer)

				TriggerClientEvent('esx:playerLoaded', _source, {
					identifier   = xPlayer.identifier,
					accounts     = xPlayer.getAccounts(),
					inventory    = xPlayer.getInventory(),
					job          = xPlayer.getJob(),
					loadout      = xPlayer.getLoadout(),
					lastPosition = xPlayer.getLastPosition(),
					money        = xPlayer.getMoney()
				})

				xPlayer.displayMoney(xPlayer.getMoney())
			end)
		end)

	end)
end)

AddEventHandler('playerDropped', function(reason)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	if xPlayer then
		TriggerEvent('esx:playerDropped', _source, reason)

		ESX.SavePlayer(xPlayer, function()
			ESX.Players[_source] = nil
			ESX.LastPlayerData[_source] = nil
		end)
	end
end)

RegisterServerEvent('esx:updateLoadout')
AddEventHandler('esx:updateLoadout', function(loadout)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.loadout = loadout
end)

RegisterServerEvent('esx:updateLastPosition')
AddEventHandler('esx:updateLastPosition', function(position)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.setLastPosition(position)
end)

RegisterServerEvent('esx:giveInventoryItem')
AddEventHandler('esx:giveInventoryItem', function(target, type, itemName, itemCount)
	local _source = source

	local sourceXPlayer = ESX.GetPlayerFromId(_source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if type == 'item_standard' then

		local sourceItem = sourceXPlayer.getInventoryItem(itemName)
		local targetItem = targetXPlayer.getInventoryItem(itemName)

		if itemCount > 0 and sourceItem.count >= itemCount then

			if targetItem.limit ~= -1 and (targetItem.count + itemCount) > targetItem.limit then
			    TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('ex_inv_lim', targetXPlayer.name)})
			else
				sourceXPlayer.removeInventoryItem(itemName, itemCount)
				targetXPlayer.addInventoryItem   (itemName, itemCount)
				
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'inform', text = _U('gave_item', targetXPlayer.name, itemCount, ESX.Items[itemName].label)})
				
			--[[MySQL.Async.execute('INSERT INTO transfer_item (Veren, Tip, Sayi, Item, Alici)VALUES (@Veren, @Tip, @Sayi, @Item, @Alici) ',
            {
                    ['@Veren']   = sourceXPlayer.name,
                    ['@Tip']   = 'Esya verdi',
                    ['@Sayi']    = itemCount,
					['@Item']    = ESX.Items[itemName].label,
                    ['@Alici']    = targetXPlayer.name

        }
            )--]]
				TriggerClientEvent('mythic_notify:client:SendAlert', target, { type = 'inform', text = _U('received_item', sourceXPlayer.name, itemCount, ESX.Items[itemName].label)})
				--TriggerServerEvent('esx_joblogs:AddInLog', "sistemlog", "itemverme", sourceXPlayer.name, targetXPlayer.name, itemCount, ESX.Items[itemName].label, "Esya verme")
				
				--Eşya verme log
				TriggerEvent("cylex:giveitemalert", sourceXPlayer.name, targetXPlayer.name, itemCount, ESX.Items[itemName].label)
				
			end

		else
		    TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('imp_invalid_quantity')})
		end

	elseif type == 'item_money' then

		if itemCount > 0 and sourceXPlayer.getMoney() >= itemCount then
			sourceXPlayer.removeMoney(itemCount)
			targetXPlayer.addMoney   (itemCount)
			local itemCount = ESX.Math.GroupDigits(itemCount)

			TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'inform', text = _U('gave_money', targetXPlayer.name, ESX.Math.GroupDigits(itemCount))})
			
			--PARA VERME LOG
			TriggerEvent("cylex:givemoneyalert", sourceXPlayer.name, targetXPlayer.name, itemCount)
			
			--[[MySQL.Async.execute('INSERT INTO transfer (Gonderen, Tip, Sayi, Alici)VALUES (@Gonderen, @Tip, @Sayi, @Alici) ',
            {
                    ['@Gonderen']   = sourceXPlayer.name,
                    ['@Tip']   = 'Nakit para verdi',
                    ['@Sayi']    = itemCount,
                    ['@Alici']    = targetXPlayer.name

        }
            )--]]
			TriggerClientEvent('mythic_notify:client:SendAlert', target, { type = 'inform', text = _U('received_money', sourceXPlayer.name, ESX.Math.GroupDigits(itemCount))})
			
		else
			TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('imp_invalid_amount')})
		end

	elseif type == 'item_account' then

		if itemCount > 0 and sourceXPlayer.getAccount(itemName).money >= itemCount then
			sourceXPlayer.removeAccountMoney(itemName, itemCount)
			targetXPlayer.addAccountMoney   (itemName, itemCount)
			
			TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'success', text = _U('gave_account_money', targetXPlayer.name, ESX.Math.GroupDigits(itemCount), Config.AccountLabels[itemName])})
			
			--BANKA PARA TRANSFER LOGU
			TriggerEvent("cylex:givemoneybankalert", sourceXPlayer.name, targetXPlayer.name, itemCount)

			--[[MySQL.Async.execute('INSERT INTO transfer (Gonderen, Tip, Sayi, Alici)VALUES (@Gonderen, @Tip, @Sayi, @Alici)) ',
            {
                    ['@Gonderen']   = sourceXPlayer.name,
                    ['@Tip']   = 'Bankadan para verdi',
                    ['@Sayi']    = itemCount,
                    ['@Alici']    = targetXPlayer.name

        }
            )--]]
			TriggerClientEvent('mythic_notify:client:SendAlert', target, { type = 'success', text = _U('received_account_money', sourceXPlayer.name, ESX.Math.GroupDigits(itemCount), Config.AccountLabels[itemName])})
			
		else
			TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('imp_invalid_amount')})
		end

	elseif type == 'item_weapon' then

		if not targetXPlayer.hasWeapon(itemName) then
			sourceXPlayer.removeWeapon(itemName)
			targetXPlayer.addWeapon(itemName, itemCount)

			local weaponLabel = ESX.GetWeaponLabel(itemName)

			if itemCount > 0 then
			    TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'success', text = _U('gave_weapon_ammo', targetXPlayer.name, itemCount, weaponLabel)})
				
				--Silah Transfer Logu
				TriggerEvent("cylex:giveweaponammoalert", sourceXPlayer.name, targetXPlayer.name, itemCount, weaponLabel)
				
			--[[MySQL.Async.execute('INSERT INTO transfer_item (Veren, Tip, Item, Alici)VALUES (@Veren, @Tip, @Item, @Alici) ',
            {
                    ['@Veren']   = sourceXPlayer.name,
                    ['@Tip']   = 'Mermili Silah verdi',
					['@Sayi']    = itemCount,
					['@Item']    = weaponLabel,
                    ['@Alici']    = targetXPlayer.name

        }
            )--]]
				TriggerClientEvent('mythic_notify:client:SendAlert', target, { type = 'success', text = _U('received_weapon_ammo', sourceXPlayer.name, itemCount, weaponLabel)})
				
			else
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'success', text = _U('gave_weapon', targetXPlayer.name, weaponLabel)})
				--Silah Transfer Logu
				TriggerEvent("cylex:giveweaponalert", sourceXPlayer.name, targetXPlayer.name, weaponLabel)
				
			--[[MySQL.Async.execute('INSERT INTO transfer_item (Veren, Tip, Item, Alici)VALUES (@Veren, @Tip, @Item, @Alici) ',
            {
                    ['@Veren']   = sourceXPlayer.name,
                    ['@Tip']   = 'Silah verdi',
					['@Item']    = weaponLabel,
                    ['@Alici']    = targetXPlayer.name

        }
            )--]]
				TriggerClientEvent('mythic_notify:client:SendAlert', target, { type = 'success', text = _U('received_weapon', sourceXPlayer.name, weaponLabel)})
			end
		else
			TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('gave_weapon_hasalready', targetXPlayer.name, weaponLabel)})
			TriggerClientEvent('mythic_notify:client:SendAlert', target, { type = 'error', text = _U('received_weapon_hasalready', sourceXPlayer.name, weaponLabel)})
		end

	end
end)

RegisterServerEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(type, itemName, itemCount)
	local _source = source

	if type == 'item_standard' then

		if itemCount == nil or itemCount < 1 then
			TriggerClientEvent('esx:showNotification', _source, _U('imp_invalid_quantity'))
		else
			local xPlayer = ESX.GetPlayerFromId(source)
			local xItem = xPlayer.getInventoryItem(itemName)

			if (itemCount > xItem.count or xItem.count < 1) then
				TriggerClientEvent('esx:showNotification', _source, _U('imp_invalid_quantity'))
			else
				xPlayer.removeInventoryItem(itemName, itemCount)

				local pickupLabel = ('~y~%s~s~ [~b~%s~s~]'):format(xItem.label, itemCount)
				ESX.CreatePickup('item_standard', itemName, itemCount, pickupLabel, _source)
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'inform', text = _U('threw_standard', itemCount, xItem.label)})

				--EŞYA ATMA LOGU
				TriggerEvent("cylex:dropitemalert", xPlayer.name, itemCount, ESX.Items[itemName].label)
			--[[MySQL.Async.execute('INSERT INTO transfer_item_drop (Atan, Tip, Item, Sayi)VALUES (@Atan, @Tip, @Item, @Sayi) ',
            {
                    ['@Atan']   = xPlayer.name,
                    ['@Tip']   = 'Yere atti',
					['@Item']   = xItem.label,
					['@Sayi']    = itemCount

        }
            )--]]
			end
		end

	elseif type == 'item_money' then

		if itemCount == nil or itemCount < 1 then
			TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('imp_invalid_amount')})
		else
			local xPlayer = ESX.GetPlayerFromId(source)
			local playerCash = xPlayer.getMoney()
			local sourceXPlayer = ESX.GetPlayerFromId(_source)
	        local targetXPlayer = ESX.GetPlayerFromId(target)
			local xMoney = ESX.Math.GroupDigits(itemCount)

			if (itemCount > playerCash or playerCash < 1) then
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('imp_invalid_amount')})
			else
				xPlayer.removeMoney(itemCount)

				--YERE PARA ATMA
				TriggerEvent("cylex:dropmoneyalert", xPlayer.name, itemCount)
				
				local pickupLabel = ('~y~%s~s~ [~g~%s~s~]'):format(_U('cash'), _U('locale_currency', ESX.Math.GroupDigits(itemCount)))
				ESX.CreatePickup('item_money', 'money', itemCount, pickupLabel, _source)
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'inform', text = _U('threw_money', ESX.Math.GroupDigits(itemCount))})
			--[[MySQL.Async.execute('INSERT INTO transfer_item_drop (Atan, Tip, Item, Sayi)VALUES (@Atan, @Tip, @Item, @Sayi) ',
            {
                    ['@Atan']   = xPlayer.name,
                    ['@Tip']   = 'Yere atti',
                    ['@Item']   = 'Para',
					['@Sayi']    = xMoney

        }
            )--]]
			end
		end

	elseif type == 'item_account' then

		if itemCount == nil or itemCount < 1 then
			TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('imp_invalid_amount')})
		else
			local xPlayer = ESX.GetPlayerFromId(source)
			local account = xPlayer.getAccount(itemName)
			local xMoney = ESX.Math.GroupDigits(itemCount)

			if (itemCount > account.money or account.money < 1) then
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('imp_invalid_amount')})
			else
				xPlayer.removeAccountMoney(itemName, itemCount)

				--BANKADAN PARA ATMA
				TriggerEvent("cylex:dropbankmoneyalert", xPlayer.name, itemCount)
	
				local pickupLabel = ('~y~%s~s~ [~g~%s~s~]'):format(account.label, _U('locale_currency', ESX.Math.GroupDigits(itemCount)))
				ESX.CreatePickup('item_account', itemName, itemCount, pickupLabel, _source)
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'inform', text = _U('threw_account', ESX.Math.GroupDigits(itemCount), string.lower(account.label))})
			--[[MySQL.Async.execute('INSERT INTO transfer_item_drop (Atan, Tip, Item, Sayi)VALUES (@Atan, @Tip, @Item, @Sayi) ',
            {
                    ['@Atan']   = xPlayer.name,
                    ['@Tip']   = 'Yere atti',
                    ['@Item']   = 'Bankadan Para',
					['@Sayi']    = xMoney

        }
            )--]]
			end
		end

	elseif type == 'item_weapon' then

		local xPlayer = ESX.GetPlayerFromId(source)
		local loadout = xPlayer.getLoadout()

		for i=1, #loadout, 1 do
			if loadout[i].name == itemName then
				itemCount = loadout[i].ammo
				break
			end
		end

		if xPlayer.hasWeapon(itemName) then
			local weaponLabel, weaponPickup = ESX.GetWeaponLabel(itemName), 'PICKUP_' .. string.upper(itemName)

			xPlayer.removeWeapon(itemName)
			
			
			if itemCount > 0 then
				TriggerClientEvent('esx:pickupWeapon', _source, weaponPickup, itemName, itemCount)
				--YERE MERMİLİ SİLAH ATMA
				TriggerEvent("cylex:dropweaponammoalert", xPlayer.name, itemCount, weaponLabel)
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'inform', text = _U('threw_weapon_ammo', weaponLabel, itemCount)})
			--[[MySQL.Async.execute('INSERT INTO transfer_item_drop (Atan, Tip, Item, Sayi)VALUES (@Atan, @Tip, @Item, @Sayi) ',
            {
                    ['@Atan']   = xPlayer.name,
                    ['@Tip']   = 'yere mermili silah atti',
                    ['@Item']   = weaponLabel,
					['@Sayi']    = itemCount

        }
            )--]]
			else
				-- workaround for CreateAmbientPickup() giving 30 rounds of ammo when you drop the weapon with 0 ammo
				
				--YERE SILAH ATMA
				TriggerEvent("cylex:dropweaponalert", xPlayer.name, weaponLabel)
				
				TriggerClientEvent('esx:pickupWeapon', _source, weaponPickup, itemName, 1)
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'inform', text = _U('threw_weapon', weaponLabel)})
			--[[MySQL.Async.execute('INSERT INTO transfer_item_drop (Atan, Tip, Item, Sayi)VALUES (@Atan, @Tip, @Item, @Sayi) ',
            {
                    ['@Atan']   = xPlayer.name,
                    ['@Tip']   = 'yere silah atti',
                    ['@Item']   = weaponLabel,
					['@Sayi']    = '1'

        }
            )--]]
			end
		end

	end
end)

RegisterServerEvent('esx:useItem')
AddEventHandler('esx:useItem', function(itemName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local count   = xPlayer.getInventoryItem(itemName).count

	if count > 0 then
		ESX.UseItem(source, itemName)
	else
	    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Geçersiz Miktar'})
	end
end)

RegisterServerEvent('esx:onPickup')
AddEventHandler('esx:onPickup', function(id)
	local _source = source
	local pickup  = ESX.Pickups[id]
	local xPlayer = ESX.GetPlayerFromId(_source)

	if pickup.type == 'item_standard' then

		local item      = xPlayer.getInventoryItem(pickup.name)
		local canTake   = ((item.limit == -1) and (pickup.count)) or ((item.limit - item.count > 0) and (item.limit - item.count)) or 0
		local total     = pickup.count < canTake and pickup.count or canTake
		local remaining = pickup.count - total

		TriggerClientEvent('esx:removePickup', -1, id)

		if total > 0 then
			xPlayer.addInventoryItem(pickup.name, total)
		end

		if remaining > 0 then
			TriggerClientEvent('esx:showNotification', _source, _U('cannot_pickup_room', item.label))

			local pickupLabel = ('~s~%s~u~ [~r~%s~u~]'):format(item.label, remaining)
			ESX.CreatePickup('item_standard', pickup.name, remaining, pickupLabel, _source)
		end

	elseif pickup.type == 'item_money' then
		TriggerClientEvent('esx:removePickup', -1, id)
		xPlayer.addMoney(pickup.count)
	elseif pickup.type == 'item_account' then
		TriggerClientEvent('esx:removePickup', -1, id)
		xPlayer.addAccountMoney(pickup.name, pickup.count)
	end
end)

ESX.RegisterServerCallback('esx:getPlayerData', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		loadout      = xPlayer.getLoadout(),
		lastPosition = xPlayer.getLastPosition(),
		money        = xPlayer.getMoney()
	})
end)

ESX.RegisterServerCallback('esx:getOtherPlayerData', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		loadout      = xPlayer.getLoadout(),
		lastPosition = xPlayer.getLastPosition(),
		money        = xPlayer.getMoney()
	})
end)

TriggerEvent("es:addGroup", "jobmaster", "user", function(group) end)

ESX.StartDBSync()
ESX.StartPayCheck()
