ESX = nil
ESXLoaded = false
if not Config.ArmesInItem then
	PlayerWeapon = {}
end

local prefix = "[^3sGangSysteme^7]"
function ToConsol(str)
	print(prefix.." "..str)
end

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent(Config.TriggerGetEsx, function(obj) ESX = obj end)
		ESXLoaded = true
		Citizen.Wait(0)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	ESX.PlayerData = ESX.GetPlayerData()

	if not Config.ArmesInItem then
		PlayerWeapon = ESX.GetWeaponList()
		for i = 1, #PlayerWeapon, 1 do
			if PlayerWeapon[i].name == 'WEAPON_UNARMED' then
				PlayerWeapon[i] = nil
			else
				PlayerWeapon[i].hash = GetHashKey(PlayerWeapon[i].name)
			end
		end
	end
end)


CurrentGangs = {}

function KeyboardInput(entryTitle, textEntry, inputText, maxLength)
	AddTextEntry(entryTitle, textEntry)
	DisplayOnscreenKeyboard(1, entryTitle, '', inputText, '', '', '', maxLength)
	blockinput = true

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Citizen.Wait(0)
	end

	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult()
		Citizen.Wait(500)
		blockinput = false
		return result
	else
		Citizen.Wait(500)
		blockinput = false
		return nil
	end
end

function CountGrade(t)
	local count = 0
	for k,v in pairs(t) do
		count = count + 1
	end
	return count+1
end

function CountTable(t)
	local count = 0
	for k,v in pairs(t) do
		count = count + 1
	end
	return count
end

function StoreVehicle(pVeh)
	local vProps = ESX.Game.GetVehicleProperties(pVeh)
	local vName = GetDisplayNameFromVehicleModel(vProps.model)
	if Config.WhitelistVeh(vProps) then
		TriggerServerEvent("sGangsSysteme:AddVehicle", CurrentGangs.name, vProps, vName)
		DeleteEntity(pVeh)
	end
end

function CheckQuantity(number)
	number = tonumber(number)
	
	if type(number) == 'number' then
		number = ESX.Math.Round(number)
		if number > 0 then
			return true, number
		end
	end
	
	return false, number
end

function GetWeight(t) 
	local count = 0
	for k,v in pairs(t) do 
		if k ~= "accounts" then
			if k == "item" then
				for a,b in pairs(v) do
					count = count + (b.count*b.itemWeight)
				end
			elseif k == "weapons" then 
				for a,b in pairs(v) do
					count = count + Config.PoidsWeapons[b.name]
				end
			end
		end
	end
	return count
end

RegisterNetEvent(Config.TriggerEsxPlayerLoaded)
AddEventHandler(Config.TriggerEsxPlayerLoaded, function(playerData)
	ESX.PlayerData = playerData
	TriggerServerEvent("sGangsSysteme:PlayerSpawned")
end)

RegisterNetEvent(Config.TriggerEsxSetjob2)
AddEventHandler(Config.TriggerEsxSetjob2, function(job)
	ESX.PlayerData.job2 = job
	TriggerServerEvent("sGangsSysteme:PlayerRefresh")
end)

RegisterNetEvent('sGangsSysteme:SpawnVehicle')
AddEventHandler('sGangsSysteme:SpawnVehicle', function(vProps)
	ESX.Game.SpawnVehicle(vProps.model, CurrentGangs.coords["Garage"].SpawnCoord.coords, CurrentGangs.coords["Garage"].SpawnCoord.heading, function(vehicle)
		ESX.Game.SetVehicleProperties(vehicle, vProps)
	end)
	RageUI.CloseAll()
end)

RegisterNetEvent('sGangsSysteme:UpdateCoffre')
AddEventHandler('sGangsSysteme:UpdateCoffre', function(data)
	CurrentGangs.data = data
end)

RegisterCommand("reload", function()
	TriggerServerEvent("sGangsSysteme:PlayerSpawned")
end, false)

local ZonesListe = {}

Citizen.CreateThread(function()
	while not ESXLoaded do 
		Wait(1)
	end

	while true do
		local isProche = false
		for k,v in pairs(ZonesListe) do
			local dist = Vdist2(GetEntityCoords(PlayerPedId(), false), v.Position)

			if dist < 250 then
				isProche = true
				if Config.Marker.UseMoins1 then
					DrawMarker(Config.Marker.MarkerId, v.Position.x, v.Position.y, v.Position.z-1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, Config.Marker.Color.R, Config.Marker.Color.G, Config.Marker.Color.B, Config.Marker.Color.A,  Config.Marker.BobUpAndDown,  Config.Marker.FaceCamera, 2,  Config.Marker.Rotate,  false, false, false)
				else 
					DrawMarker(Config.Marker.MarkerId, v.Position.x, v.Position.y, v.Position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, Config.Marker.Color.R, Config.Marker.Color.G, Config.Marker.Color.B, Config.Marker.Color.A,  Config.Marker.BobUpAndDown,  Config.Marker.FaceCamera, 2,  Config.Marker.Rotate,  false, false, false)
				end
			end
			if dist < 10 then
				ESX.ShowHelpNotification(Config.PrefixColorHelpNotif..CurrentGangs.label.."\n~w~Appuyez sur ~INPUT_CONTEXT~ pour interagir")
				if IsControlJustPressed(1,51) then
					if k == "BossMenu" then 
						if ESX.PlayerData.job2 and ESX.PlayerData.job2.grade_name == "boss" then 
							Config.BossAction(ESX.PlayerData.job2)
						else 
							ESX.ShowNotification("~g~Boss "..CurrentGangs.label.."\n~s~Vous n'êtes pas le boss.")
						end
					elseif k == "Coffre" then
						local PlayerAlreadyInCoffre = false
						local loaded = false 
						
						ESX.TriggerServerCallback('sGangsSysteme:CheckIfPlayerInCoffre', function(isAvailabe)
							PlayerAlreadyInCoffre = isAvailabe
							loaded = true
						end, CurrentGangs.name)
					
						while not loaded do 
							Wait(1)
						end
					
						if PlayerAlreadyInCoffre then 
							ESX.ShowNotification("~g~Coffre "..CurrentGangs.label.."\n~s~Il y a quelqu'un qui regarde ce coffre.")
						else
							OpenMenuCoffre()
						end
					elseif k == "RangeVeh" then 
						local pPed = PlayerPedId()
						if IsPedInAnyVehicle(pPed, true) then 
							local pVeh = GetVehiclePedIsIn(pPed, false)
							StoreVehicle(pVeh)
						else 
							ESX.ShowNotification("~g~Garage "..CurrentGangs.label.."\n~s~Vous devez être dans un vehicule.")
						end
					elseif k == "ExitVeh" then 
						local PlayerAlreadyInGarage = false
						local loaded = false 
						
						ESX.TriggerServerCallback('sGangsSysteme:CheckIfPlayerInGarage', function(isAvailabe)
							PlayerAlreadyInGarage = isAvailabe
							loaded = true
						end, CurrentGangs.name)
					
						while not loaded do 
							Wait(1)
						end
					
						if PlayerAlreadyInGarage then 
							ESX.ShowNotification("~g~Garage "..CurrentGangs.label.."\n~s~Il y a quelqu'un qui regarde ce coffre.")
						else
							OpenMenuGarage()
						end
					end
				end
			end
		end
		
		if isProche then
			Wait(0)
		else
			Wait(750)
		end
	end
end)

function AddZones(zoneName, data)
	if not ZonesListe[zoneName] then
		ZonesListe[zoneName] = data
		ToConsol("Creation d'une zone (ZoneName:"..zoneName..")")
		return true
	else 
		ToConsol("Tentative de cree une zone qui exise deja (ZoneName:"..zoneName..")")
		return false
	end
end

function RemoveZone(zoneName)
	if ZonesListe[zoneName] then
		ZonesListe[zoneName] = nil
		ToConsol("Suppression d'une zone (ZoneName:"..zoneName..")")
	else 
		ToConsol("Tentative de supprimer une zone qui exise pas (ZoneName:"..zoneName..")")
	end
end

RegisterNetEvent("sGangsSysteme:PlayerSpawned")
AddEventHandler("sGangsSysteme:PlayerSpawned", function(t)
	if t then
		CurrentGangs = t
		for k,v in pairs(t.coords) do 
			if k ~= "Garage" then 
				AddZones(k, {
					Position = vector3(v.x, v.y, v.z)
				})
			end
		end
		for k,v in pairs(t.coords["Garage"]) do 
			if k ~= "SpawnCoord" then
				AddZones(k, {
					Position = vector3(v.x, v.y, v.z)
				})
			end
		end
	end
end)

RegisterNetEvent("sGangsSysteme:PlayerRefresh")
AddEventHandler("sGangsSysteme:PlayerRefresh", function(hasJob, t)
	if hasJob then 
		if t then
			for k,v in pairs(ZonesListe) do 
				RemoveZone(k)
			end
			CurrentGangs = t
			for k,v in pairs(t.coords) do 
				if k ~= "Garage" then 
					AddZones(k, {
						Position = vector3(v.x, v.y, v.z)
					})
				end
			end
			for k,v in pairs(t.coords["Garage"]) do 
				if k ~= "SpawnCoord" then
					AddZones(k, {
						Position = vector3(v.x, v.y, v.z)
					})
				end
			end
		end
	else 
		for k,v in pairs(ZonesListe) do 
			RemoveZone(k)
		end
	end
end)

local List = {
	Actions = {
		"Deposer",
		"Prendre"
	},
	ActionIndex = 1
}

function OpenMenuCoffre()
	TriggerServerEvent("sGangsSysteme:playerOpenedCoffre", CurrentGangs.name) -- ANTI DUPIS

	local ItemLoaded = false
	ESX.TriggerServerCallback("sGangsSysteme:GetItemGangs", function(result) 
		CurrentGangs.data = result
		ItemLoaded = true
	end, CurrentGangs.name)

	while not ItemLoaded do Wait(1) end

	local menu = RageUI.CreateMenu("Coffre", "Que souhaitez-vous faire ?")
	local depositMenu = RageUI.CreateSubMenu(menu, "Deposer", "Contenu de vos poche")

	RageUI.Visible(menu, not RageUI.Visible(menu))
	local UsedPoids = 0

	while menu do
		Wait(0)
		RageUI.IsVisible(menu, function()

			RageUI.Separator("Poids : "..GetWeight(CurrentGangs.data).."/"..Config.CoffrePoidsMax)
			RageUI.Button("Deposer du contenu", nil, { RightLabel = "→→→" }, true, {}, depositMenu)
			RageUI.Separator("↓ Contenu du coffre ↓")
			RageUI.List("[~r~"..CurrentGangs.data["accounts"][Config.MoneyType.money].."$~s~] Argent", List.Actions, List.ActionIndex, nil, {}, true, {
				onListChange = function(Index, Item)
					List.ActionIndex = Index;
				end,
				onSelected = function()
					if List.ActionIndex == 1 then 
						if UpdateOnscreenKeyboard() == 0 then return end
						local result = KeyboardInput('Combien voulez vous deposer ?', 'Combien voulez vous deposer ?', "", 10)
						local valide, number = CheckQuantity(result)
						if valide then
							TriggerServerEvent("sGangsSysteme:AddMoney", CurrentGangs.name, Config.MoneyType.money, number)
						end
					elseif List.ActionIndex == 2 then
						if UpdateOnscreenKeyboard() == 0 then return end
						local result = KeyboardInput('Combien voulez vous prendre ?', 'Combien voulez vous prendre ?', "", 10)
						local valide, number = CheckQuantity(result)
						if valide then
							if CurrentGangs.data["accounts"][Config.MoneyType.money] >= number then
								TriggerServerEvent("sGangsSysteme:SuppMoney", CurrentGangs.name, Config.MoneyType.money, number)
							end
						end
					end
				end
			})
			RageUI.List("[~r~"..CurrentGangs.data["accounts"][Config.MoneyType.black_money].."$~s~] Argent sale", List.Actions, List.ActionIndex, nil, {}, true, {
				onListChange = function(Index, Item)
					List.ActionIndex = Index;
				end,
				onSelected = function()
					if List.ActionIndex == 1 then 
						if UpdateOnscreenKeyboard() == 0 then return end
						local result = KeyboardInput('Combien voulez vous deposer ?', 'Combien voulez vous deposer ?', "", 10)
						local valide, number = CheckQuantity(result)
						if valide then
							TriggerServerEvent("sGangsSysteme:AddMoney", CurrentGangs.name, Config.MoneyType.black_money, number)
						end
					elseif List.ActionIndex == 2 then
						if UpdateOnscreenKeyboard() == 0 then return end
						local result = KeyboardInput('Combien voulez vous prendre ?', 'Combien voulez vous prendre ?', "", 10)
						local valide, number = CheckQuantity(result)
						if valide then
							if CurrentGangs.data["accounts"][Config.MoneyType.black_money] >= number then
								TriggerServerEvent("sGangsSysteme:SuppMoney", CurrentGangs.name, Config.MoneyType.black_money, number)
							else 
								ESX.ShowNotification("~g~Coffre "..CurrentGangs.label.."~s~\nIl n'y a pas cette quantitee.")
							end
						end
					end
				end
			})
			if json.encode(CurrentGangs.data["item"]) ~= "[]" then
				for k,v in pairs(CurrentGangs.data["item"]) do
					RageUI.Button(v.label, nil, { RightLabel = "Quantite(s) : ~r~x"..v.count.."~s~ - ~b~Prendre~s~ →→→" }, true, {
						onSelected = function()
							if UpdateOnscreenKeyboard() == 0 then return end
							local result = KeyboardInput('Combien voulez vous prendre ?', 'Combien voulez vous prendre ?', v.count, 10)
							local valide, number = CheckQuantity(result)
							if valide then
								if v.count >= number then
									TriggerServerEvent("sGangsSysteme:SuppItem", CurrentGangs.name, v.name, number)
								else
									ESX.ShowNotification("~g~Coffre"..CurrentGangs.label.."\n~s~Vous n'avez pas cette quantite sur vous !")
								end
							else
								ESX.ShowNotification("~g~Coffre"..CurrentGangs.label.."\n~s~Vous avez mal renseignez ce champs.")
							end
						end
					})
				end
			else 
				RageUI.Separator("")
				RageUI.Separator("~r~Il n'y aucun item dans le coffre.")
				RageUI.Separator("")
			end
			if not Config.ArmesInItem then 
				if json.encode(CurrentGangs.data["weapons"]) ~= "[]" then
					for k,v in pairs(CurrentGangs.data["weapons"]) do
						RageUI.Button(v.label, nil, { RightLabel = "Munition(s) : ~r~x"..v.ammo.."~s~ - ~b~Prendre~s~ →→→" }, true, {
							onSelected = function()
								TriggerServerEvent("sGangsSysteme:SuppWeapons", CurrentGangs.name, k, v.name, ammo)
							end
						})
					end
				else 
					RageUI.Separator("")
					RageUI.Separator("~r~Il n'y aucune armes dans le coffre.")
					RageUI.Separator("")
				end
			end

		end, function()
		end)

		RageUI.IsVisible(depositMenu, function()

			RageUI.Separator("↓ ~b~Items~s~ ↓")
			ESX.PlayerData = ESX.GetPlayerData()
			for i = 1, #ESX.PlayerData.inventory do
				if ESX.PlayerData.inventory[i].count > 0 then
					RageUI.Button(ESX.PlayerData.inventory[i].label, nil, { RightLabel = "Quantite(s) : ~r~x"..ESX.PlayerData.inventory[i].count.."~s~ - ~b~Deposer~s~ →→→" }, true, {
						onSelected = function()
							if UpdateOnscreenKeyboard() == 0 then return end
							local result = KeyboardInput('Combien voulez vous deposer ?', 'Combien voulez vous deposer ?', ESX.PlayerData.inventory[i].count, 10)
							local valide, number = CheckQuantity(result)
							if valide then
								if ESX.PlayerData.inventory[i].count >= number then
									TriggerServerEvent("sGangsSysteme:AddItem", CurrentGangs.name, ESX.PlayerData.inventory[i].name, number)
								else
									ESX.ShowNotification("~g~Coffre"..CurrentGangs.label.."\n~s~Vous n'avez pas cette quantite sur vous !")
								end
							else
								ESX.ShowNotification("~g~Coffre"..CurrentGangs.label.."\n~s~Vous avez mal renseignez ce champs.")
							end
						end
					})
				end
			end
			if not Config.ArmesInItem then 
				RageUI.Separator("↓ ~b~Armes~s~ ↓")
				local pPed = PlayerPedId()
				for i = 1, #PlayerWeapon, 1 do
					if HasPedGotWeapon(pPed, PlayerWeapon[i].hash, false) then
						local ammo = GetAmmoInPedWeapon(pPed, PlayerWeapon[i].hash)
						RageUI.Button(PlayerWeapon[i].label, nil, { RightLabel = "Munition(s) : ~r~x"..ammo.."~s~ - ~b~Deposer~s~ →→→" }, true, {
							onSelected = function()
								TriggerServerEvent("sGangsSysteme:AddWeapons", CurrentGangs.name, PlayerWeapon[i].name, ammo)
							end
						})
					end
				end
			end

		end, function()
		end)

		if not RageUI.Visible(menu) and not RageUI.Visible(depositMenu) then
			menu = RMenu:DeleteType('menu', true)
			depositMenu = RMenu:DeleteType('depositMenu', true)
			TriggerServerEvent("sGangsSysteme:playerClosedCoffre", CurrentGangs.name)
		end
	end
end

local function OpenMenu()
	local menu = RageUI.CreateMenu("Creation de gang", "Veuillez remplir chacun des parametres")
	local gradesMenu = RageUI.CreateSubMenu(menu, "Grades", "Creations des grades")
	
	RageUI.Visible(menu, not RageUI.Visible(menu))

	local Gangs = {
		Name = "",
		Label = "",
		Coords = {
			BossMenu = nil,
			Garage = {
				ExitVeh = nil,
				SpawnCoord = nil,
				RangeVeh = nil,
			},
			Coffre = nil
		},
		Grades = {
			["1"] = {
				name = "boss",
				label = ""
			}
		}
	}
	local idxList = 1
	local GradeCount = 0

	while menu do
		Wait(0)
		RageUI.IsVisible(menu, function()

			RageUI.Button('Nom du gang', nil, { RightLabel = "~b~"..Gangs.Label }, true, {
				onSelected = function()
					local result = KeyboardInput('Nom du gang', ('Nom du gang'), '', 50)
					if result and result ~= "" then 
						Gangs.Label = tostring(result)
						Gangs.Name = string.lower(string.gsub(result, "%s+", "_"))
					else 
						ESX.ShowNotification("~r~Creation de gang~s~\nVous avez mal renseigne ce parametre.")
					end
				end
			})
			local BossMenu
			if Gangs.Coords.BossMenu == nil then 
				BossMenu = "~r~Non definis"
			else 
				BossMenu = "~b~Definis"
			end 
			RageUI.Button('Position du menu boss', nil, { RightLabel = BossMenu }, true, {
				onSelected = function()
					local pPed = PlayerPedId()
					local pCoords = GetEntityCoords(pPed)
					Gangs.Coords.BossMenu = pCoords
					ESX.ShowNotification("~r~Creation de gang~s~\nVous avez definis : ~b~Boss menu~s~.")
				end
			})
			local ExitVeh
			local RangeVeh
			local SpawnVeh
			if Gangs.Coords.Garage.ExitVeh == nil then 
				ExitVeh = "~r~Non definis~s~"
			else 
				ExitVeh = "~b~Definis~s~"
			end
			if Gangs.Coords.Garage.RangeVeh == nil then 
				RangeVeh = "~r~Non definis~s~"
			else 
				RangeVeh = "~b~Definis~s~"
			end 
			if Gangs.Coords.Garage.SpawnCoord == nil then 
				SpawnVeh = "~r~Non definis~s~"
			else 
				SpawnVeh = "~b~Definis~s~"
			end
			RageUI.List("Position garage :", {
				{Name = "Sortir vehicule", Value = 1},
				{Name = "Ranger vehicule", Value = 2},
				{Name = "Spawn vehicule", Value = 3},
			}, idxList, "Sortir vehicule : "..ExitVeh.."\nRanger vehicule : "..RangeVeh.."\nSpawn vehicule : "..SpawnVeh, {}, not notPersonnal, {
				onListChange = function(Index, Item)
					idxList = Index;
				end,
				onSelected = function()
					if idxList == 1 then 
						local pPed = PlayerPedId()
						local pCoords = GetEntityCoords(pPed)
						Gangs.Coords.Garage.ExitVeh = pCoords
						ESX.ShowNotification("~r~Creation de gang~s~\nVous avez definis : ~b~Sortir vehicule~s~.")
					elseif idxList == 2 then 
						local pPed = PlayerPedId()
						local pCoords = GetEntityCoords(pPed)
						Gangs.Coords.Garage.RangeVeh = pCoords
						ESX.ShowNotification("~r~Creation de gang~s~\nVous avez definis : ~b~Ranger vehicule~s~.")
					elseif idxList == 3 then 
						local pPed = PlayerPedId()
						local pCoords = GetEntityCoords(pPed)
						local pHeading = GetEntityHeading(pPed)
						Gangs.Coords.Garage.SpawnCoord = {coords = pCoords, heading = pHeading}
						ESX.ShowNotification("~r~Creation de gang~s~\nVous avez definis : ~b~Spawn vehicule~s~.")
					end
				end
			})
			local CoffreMenu
			if Gangs.Coords.Coffre == nil then 
				CoffreMenu = "~r~Non definis"
			else 
				CoffreMenu = "~b~Definis"
			end 
			RageUI.Button('Position du coffre', nil, { RightLabel = CoffreMenu }, true, {
				onSelected = function()
					local pPed = PlayerPedId()
					local pCoords = GetEntityCoords(pPed)
					Gangs.Coords.Coffre = pCoords
					ESX.ShowNotification("~r~Creation de gang~s~\nVous avez definis : ~b~Coffre menu~s~.")
				end
			})
			RageUI.Button('Liste des grades', nil, { RightLabel = "→→→" }, true, {}, gradesMenu)
			RageUI.Button('Valider et cree le gang '..Gangs.Label, nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					if Gangs.Name == "" or Gangs.Label == "" or Gangs.Coords.BossMenu == nil or Gangs.Coords.Garage.ExitVeh == nil or Gangs.Coords.Garage.SpawnCoord == nil or Gangs.Coords.Garage.RangeVeh == nil or Gangs.Coords.Coffre == nil then 
						ESX.ShowNotification("~r~Creation de gang~s~\nUn parametre n'est pas definis.")
					else 
						if GradeCount >= 1 then 
							TriggerServerEvent("sGangsSysteme:CreateGangs", Gangs)
							RageUI.CloseAll()
						else
							ESX.ShowNotification("~r~Creation de gang~s~\nIl dois y avoir minimum 1 grade de cree.")
						end
					end
				end
			})

		end, function()
		end)

		RageUI.IsVisible(gradesMenu, function()

			RageUI.Button("Ajouter un grade", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					local result = KeyboardInput('Nom du grade', ('Nom du grade'), '', 50)
					if result and result ~= "" then 
						local Exist = false
						local GradeTable = {}
						for k,v in pairs(Gangs.Grades) do 
							table.insert(GradeTable, tonumber(k))
							if v.label == result then 
								ESX.ShowNotification("~r~Creation de gang~s~\nUn grade à dejà ce nom.")
								Exist = true
							end
						end
						if not Exist then
							local noSpace = string.lower(string.gsub(result, "%s+", "_"))
							local max = CountGrade(GradeTable)
							if not Gangs.Grades[max] then 
								Gangs.Grades[max] = {}
								Gangs.Grades[max].name = noSpace
								Gangs.Grades[max].label = tostring(result)
								GradeCount = GradeCount + 1
							end
						end
					else 
						ESX.ShowNotification("~r~Creation de gang~s~\nVous avez mal renseigne ce parametre.")
					end
				end
			})
			if json.encode(Gangs.Grades) ~= "[]" then 
				RageUI.Separator("↓ Grades cree ↓")
			end
			local GradeLabel
			local GradeRight
			if Gangs.Grades["1"].label == "" then 
				GradeLabel = "[~r~Obligatoire~s~] Grade patron/boss"
				GradeRight = "~r~À definir~s~ →→→"
			else 
				GradeLabel = Gangs.Grades["1"].label
				GradeRight = "~b~Definis / Modifier"
			end 
			RageUI.Button(GradeLabel, nil, { RightLabel = GradeRight }, true, {
				onSelected = function()
					local result = KeyboardInput('Nom du grade', ('Nom du grade'), '', 50)
					if result and result ~= "" then 
						Gangs.Grades["1"].label = tostring(result)                  
					else 
						ESX.ShowNotification("~r~Creation de gang~s~\nVous avez mal renseigne ce parametre.")
					end
				end
			})
			for k,v in pairs(Gangs.Grades) do 
				if v.name ~= "boss" then
					RageUI.Button(v.label, nil, { RightLabel = "~r~Supprimer~s~ →→→" }, true, {
						onSelected = function()
							Gangs.Grades[k] = nil
							GradeCount = GradeCount - 1
						end
					})
				end
			end

		end, function()
		end)

		if not RageUI.Visible(menu) and not RageUI.Visible(gradesMenu) then
			menu = RMenu:DeleteType('menu', true)
			gradesMenu = RMenu:DeleteType('gradesMenu', true)
		end
	end
end
RegisterNetEvent("sGangSysteme:OpenMenuCreator")
AddEventHandler("sGangSysteme:OpenMenuCreator", OpenMenu)

function OpenMenuGarage()
	TriggerServerEvent("sGangsSysteme:playerOpenedGarage", CurrentGangs.name) -- ANTI DUPIS
	local VehLoaded = false
	ESX.TriggerServerCallback("sGangsSysteme:GetVehiclesGangs", function(result) 
		CurrentGangs.vehicle = result
		VehLoaded = true
	end, CurrentGangs.name)

	while not VehLoaded do Wait(1) end

	local VehCount = CountTable(CurrentGangs.vehicle)
	local menu = RageUI.CreateMenu("Garage "..CurrentGangs.label, "Il y a "..VehCount.." vehicule(s) dans ce garage")

	RageUI.Visible(menu, not RageUI.Visible(menu))

	while menu do
		Wait(0)
		RageUI.IsVisible(menu, function()

			if VehCount > 0 then 
				for k,v in pairs(CurrentGangs.vehicle) do 
					local vName = GetDisplayNameFromVehicleModel(v.model)
					RageUI.Button("[~b~"..v.plate.."~s~] - "..vName, nil, { RightLabel = "~b~Sortir~s~ →→→" }, true, {
						onSelected = function()
							TriggerServerEvent("sGangsSysteme:SuppVehicle", CurrentGangs.name, v.plate, vName)
						end
					})
				end
			else 
				RageUI.Separator("")
				RageUI.Separator("~r~Il n'y aucun vehicule dans le garage.")
				RageUI.Separator("")
			end

		end, function()
		end)

		if not RageUI.Visible(menu) then
			menu = RMenu:DeleteType('menu', true)
			TriggerServerEvent("sGangsSysteme:playerClosedGarage", CurrentGangs.name)
		end
	end
end