-- bypassing equipping for spawner    
local originalRemotes = {}    
local routerInit = debug.getupvalue(    
require(game.ReplicatedStorage.Fsys).load('RouterClient').init,    
7    
)    
for i, v in pairs(routerInit) do    
    v.Name = i    
    originalRemotes[i] = v    
end    
local Fsys = require(game:GetService('ReplicatedStorage'):WaitForChild('Fsys'))    
local UIManager = Fsys.load('UIManager')    
local toys = Fsys.load('ClientData').get('inventory').toys    
local licenseUniqueId    
for i, v in pairs(toys) do    
    if v.id == 'trade_license' then    
        licenseUniqueId = i    
        break    
    end    
end    
local function hookedEquip(player, uniqueId, ...)    
    if uniqueId == licenseUniqueId then    
        UIManager.set_app_visibility('TradeHistoryApp', true)    
    end    
    return originalRemotes['ToolAPI/Equip'](player, uniqueId, ...)    
end    
local function hookedUnequip(player, uniqueId)    
    if uniqueId == licenseUniqueId then    
        UIManager.set_app_visibility('TradeHistoryApp', false)    
    end    
    return originalRemotes['ToolAPI/Unequip'](player, uniqueId)    
end    
debug.setupvalue(    
    require(game.ReplicatedStorage.Fsys).load('RouterClient').init,    
    7,    
    setmetatable({    
        ['ToolAPI/Equip'] = hookedEquip,    
        ['ToolAPI/Unequip'] = hookedUnequip,    
    }, {    
        __index = originalRemotes,    
        __newindex = function(t, k, v)    
            if k == 'ToolAPI/Equip' or k == 'ToolAPI/Unequip' then    
                rawset(t, k, v)    
            else    
                originalRemotes[k] = v    
            end    
        end,    
    })    
)    
-- hooking so trades can show visual pets    
local Players = game:GetService('Players')    
local ReplicatedStorage = game:GetService('ReplicatedStorage')    
local Fsys = require(ReplicatedStorage:WaitForChild('Fsys'))    
local UIManager = Fsys.load('UIManager')    
local TradeHistoryApp = UIManager.apps.TradeHistoryApp    
local TradeApp = UIManager.apps.TradeApp    
local LocalPlayer = Players.LocalPlayer    
if TradeHistoryApp._ORIGINAL_create_trade_frame then    
    TradeHistoryApp._create_trade_frame =    
        TradeHistoryApp._ORIGINAL_create_trade_frame    
end    
if TradeApp._ORIGINAL_change_local_trade_state then    
    TradeApp._change_local_trade_state =    
        TradeApp._ORIGINAL_change_local_trade_state    
end    
if TradeApp._ORIGINAL_overwrite_local_trade_state then    
    TradeApp._overwrite_local_trade_state =    
        TradeApp._ORIGINAL_overwrite_local_trade_state    
end    
TradeHistoryApp._ORIGINAL_create_trade_frame =    
    TradeHistoryApp._create_trade_frame    
TradeApp._ORIGINAL_change_local_trade_state = TradeApp._change_local_trade_state    
TradeApp._ORIGINAL_overwrite_local_trade_state =    
    TradeApp._overwrite_local_trade_state    
local tradeOffers = {}    
TradeApp._change_local_trade_state = function(self, change, ...)    
    local state = self:_get_local_trade_state()    
    if state and state.trade_id then    
        if state.sender == LocalPlayer and change.sender_offer then    
            tradeOffers[state.trade_id] = {    
                items = table.clone(change.sender_offer.items),    
                isSender = true,    
            }    
        elseif state.recipient == LocalPlayer and change.recipient_offer then    
            tradeOffers[state.trade_id] = {    
                items = table.clone(change.recipient_offer.items),    
                isSender = false,    
            }    
        end    
    end    
    return TradeApp._ORIGINAL_change_local_trade_state(self, change, ...)    
end    
TradeApp._overwrite_local_trade_state = function(self, trade, ...)    
    if not trade and TradeApp._last_trade_id then    
        tradeOffers[TradeApp._last_trade_id] = nil    
    end    
    return TradeApp._ORIGINAL_overwrite_local_trade_state(self, trade, ...)    
end    
TradeHistoryApp._create_trade_frame = function(self, tradeData, ...)    
    if tradeData.trade_id and tradeOffers[tradeData.trade_id] then    
        local offer = tradeOffers[tradeData.trade_id]    
        local modified = table.clone(tradeData)    
        if offer.isSender then    
            modified.sender_items = table.clone(offer.items)    
        else    
            modified.recipient_items = table.clone(offer.items)    
        end    
        return self._ORIGINAL_create_trade_frame(self, modified, ...)    
    end    
    return self._ORIGINAL_create_trade_frame(self, tradeData, ...)    
end    
-- hooking so visual pets can add to trade    
local ReplicatedStorage = game:GetService('ReplicatedStorage')    
local Players = game:GetService('Players')    
local Fsys = require(ReplicatedStorage:WaitForChild('Fsys'))    
local UIManager = Fsys.load('UIManager')    
local data    
local _overwrite_local_trade_state =    
    UIManager.apps.TradeApp._overwrite_local_trade_state    
UIManager.apps.TradeApp._overwrite_local_trade_state = function(    
    self,    
    trade,    
    ...    
)    
    if trade then    
        local offer = trade.sender == Players.LocalPlayer and trade.sender_offer    
            or trade.recipient == Players.LocalPlayer    
            and trade.recipient_offer    
        if offer then    
            if data then    
                offer.items = data    
            end    
        end    
    else    
        data = nil    
    end    
    return _overwrite_local_trade_state(self, trade, ...)    
end    
local _change_local_trade_state =    
    UIManager.apps.TradeApp._change_local_trade_state    
UIManager.apps.TradeApp._change_local_trade_state = function(self, change, ...)    
    local trade = UIManager.apps.TradeApp.local_trade_state    
    if trade then    
        local team = trade.sender == Players.LocalPlayer and 'sender_offer'    
            or trade.recipient == Players.LocalPlayer and 'recipient_offer'    
        if team then    
            local offer = change[team]    
            if offer and offer.items then    
                data = offer.items    
            end    
        end    
    end    
    return _change_local_trade_state(self, change, ...)    
end    
  
-- spawner    
local TweenService = game:GetService('TweenService')    
local Players = game:GetService('Players')    
local LocalPlayer = Players.LocalPlayer    
local RunService = game:GetService('RunService')    
local activeFlags = { F = false, R = false, N = false, M = false }    
local baseColors = {    
    Color3.fromRGB(170, 0, 255), -- Mega Neon (purple)    
    Color3.fromRGB(0, 255, 100), -- Neon (green)    
    Color3.fromRGB(0, 200, 255), -- Fly (blue)    
    Color3.fromRGB(255, 50, 150), -- Ride (pink)    
}    
  
-- Pet spawning logic    
task.spawn(function()    
    local load = require(game.ReplicatedStorage:WaitForChild('Fsys')).load    
    set_thread_identity(2)    
    local clientData = load('ClientData')    
    local items = load('KindDB')    
    local router = load('RouterClient')    
    local downloader = load('DownloadClient')    
    local animationManager = load('AnimationManager')    
    local petRigs = load('new:PetRigs')    
    local AilmentsClient = load('new:AilmentsClient')    
    local AilmentsDB = load('new:AilmentsDB')    
    set_thread_identity(8)    
  
    local petModels = {}    
    local pets = {}    
    local equippedPet = nil    
    local mountedPet = nil    
    local currentMountTrack = nil    
  
    -- Ailment injection: hook get_server so our spawned pets get fake ailments    
    local cachedAilments = {}    
    local originalGetServer = clientData.get_server    
    clientData.get_server = function(player, key, ...)    
        local data = originalGetServer(player, key, ...)    
        if key == 'ailments_manager' and player == game.Players.LocalPlayer then    
            local cloned = {}    
            if data then    
                for k, v in pairs(data) do    
                    cloned[k] = type(v) == 'table' and table.clone(v) or v    
                end    
            end    
            cloned.ailments = cloned.ailments or {}    
            for petUniqueId, _ in pairs(pets) do    
                if cachedAilments[petUniqueId] then    
                    cloned.ailments[petUniqueId] = cachedAilments[petUniqueId]    
                else    
                    local ailmentTypes = {}    
                    for kind, _ in pairs(AilmentsDB) do    
                        if kind ~= 'at_work' and kind ~= 'mystery' and kind ~= 'walking' then    
                            table.insert(ailmentTypes, kind)    
                        end    
                    end    
                    local numAilments = math.random(2, 4)    
                    local ailments = {}    
                    local usedTypes = {}    
                    for i = 1, math.min(numAilments, #ailmentTypes) do    
                        local ailmentType    
                        repeat    
                            ailmentType = ailmentTypes[math.random(1, #ailmentTypes)]    
                        until not usedTypes[ailmentType]    
                        usedTypes[ailmentType] = true    
                        local ailmentId = game:GetService('HttpService'):GenerateGUID(false)    
                        ailments[ailmentId] = {    
                            components = {},    
                            created_timestamp = os.time(),    
                            kind = ailmentType,    
                            progress = 0,    
                            rate = 0,    
                            rate_timestamp = os.time(),    
                            sort_order = i * 100,    
                        }    
                    end    
                    cachedAilments[petUniqueId] = ailments    
                    cloned.ailments[petUniqueId] = ailments    
                end    
            end    
            return cloned    
        end    
        return data    
    end    
  
    local function updateData(key, action)    
        local data = clientData.get(key)    
        local clonedData = table.clone(data)    
        clientData.predict(key, action(clonedData))    
    end    
  
    local function getUniqueId()    
        local HttpService = game:GetService('HttpService')    
        return HttpService:GenerateGUID(false)    
    end    
  
    local function getPetModel(kind)    
        if petModels[kind] then    
            return petModels[kind]    
        end    
        local streamed = downloader.promise_download_copy('Pets', kind):expect()    
        petModels[kind] = streamed    
        return streamed    
    end    
  
    local function createPet(id, properties)    
        local uniqueId = getUniqueId()    
        local item = items[id]    
        if not item then    
            warn('Pet ID not found: ' .. id)    
            return nil    
        end    
        set_thread_identity(2)    
        local new_pet = {    
            unique = uniqueId,    
            category = 'pets',    
            id = id,    
            kind = item.kind,    
            newness_order = math.random(1, 900000),    
            properties = properties or {},    
        }    
        local inventory = clientData.get('inventory')    
        inventory.pets[uniqueId] = new_pet    
        set_thread_identity(8)    
        pets[uniqueId] = {    
            data = new_pet,    
            model = nil,    
        }    
        return new_pet    
    end    
  
    -- Toy spawning function    
    local function createToy(id)    
        local uniqueId = getUniqueId()    
        local item = items[id]    
        if not item then    
            warn('Toy ID not found: ' .. id)    
            return nil    
        end    
        set_thread_identity(2)    
        local new_toy = {    
            unique = uniqueId,    
            category = 'toys',    
            id = id,    
            kind = item.kind,    
            newness_order = math.random(1, 900000),    
            properties = {},    
        }    
        local inventory = clientData.get('inventory')    
        inventory.toys[uniqueId] = new_toy    
        set_thread_identity(8)    
        return new_toy    
    end    
  
    local function neonify(model, entry)    
        local petModel = model:FindFirstChild('PetModel')    
        if not petModel then return end    
        for neonPart, configuration in pairs(entry.neon_parts) do    
            local trueNeonPart =    
                petRigs.get(petModel).get_geo_part(petModel, neonPart)    
            trueNeonPart.Material = configuration.Material    
            trueNeonPart.Color = configuration.Color    
        end    
    end    
  
    local function addPetWrapper(wrapper)    
        updateData('pet_char_wrappers', function(petWrappers)    
            wrapper.unique = #petWrappers + 1    
            wrapper.index = #petWrappers + 1    
            petWrappers[#petWrappers + 1] = wrapper    
            return petWrappers    
        end)    
    end    
  
    local function addPetState(state)    
        updateData('pet_state_managers', function(petStates)    
            petStates[#petStates + 1] = state    
            return petStates    
        end)    
    end    
  
    local function findIndex(array, finder)    
        for index, value in pairs(array) do    
            local isIt = finder(value, index)    
            if isIt then return index end    
        end    
        return nil    
    end    
  
    local function removePetWrapper(uniqueId)    
        updateData('pet_char_wrappers', function(petWrappers)    
            local index = findIndex(petWrappers, function(wrapper)    
                return wrapper.pet_unique == uniqueId    
            end)    
            if not index then return petWrappers end    
            table.remove(petWrappers, index)    
            for wrapperIndex, wrapper in pairs(petWrappers) do    
                wrapper.unique = wrapperIndex    
                wrapper.index = wrapperIndex    
            end    
            return petWrappers    
        end)    
    end    
  
    local function clearPetState(uniqueId)    
        local pet = pets[uniqueId]    
        if not pet then return end    
        if not pet.model then return end    
        updateData('pet_state_managers', function(states)    
            local index = findIndex(states, function(state)    
                return state.char == pet.model    
            end)    
            if not index then return states end    
            local clonedStates = table.clone(states)    
            clonedStates[index] = table.clone(clonedStates[index])    
            clonedStates[index].states = {}    
            return clonedStates    
        end)    
    end    
  
    local function setPetState(uniqueId, id)    
        local pet = pets[uniqueId]    
        if not pet then return end    
        if not pet.model then return end    
        updateData('pet_state_managers', function(states)    
            local index = findIndex(states, function(state)    
                return state.char == pet.model    
            end)    
            if not index then return states end    
            local clonedStates = table.clone(states)    
            clonedStates[index] = table.clone(clonedStates[index])    
            clonedStates[index].states = { { id = id } }    
            return clonedStates    
        end)    
    end    
  
    local function attachPlayerToPet(pet)    
        local character = game.Players.LocalPlayer.Character    
        if not character then return false end    
        if not character.PrimaryPart then return false end    
        local ridePosition = pet:FindFirstChild('RidePosition', true)    
        if not ridePosition then return false end    
        local sourceAttachment = Instance.new('Attachment')    
        sourceAttachment.Parent = ridePosition    
        sourceAttachment.Position = Vector3.new(0, 1.237, 0)    
        sourceAttachment.Name = 'SourceAttachment'    
        local stateConnection = Instance.new('RigidConstraint')    
        stateConnection.Name = 'StateConnection'    
        stateConnection.Attachment0 = sourceAttachment    
        stateConnection.Attachment1 = character.PrimaryPart.RootAttachment    
        stateConnection.Parent = character    
        return true    
    end    
  
    local function clearPlayerState()    
        updateData('state_manager', function(state)    
            local clonedState = table.clone(state)    
            clonedState.states = {}    
            clonedState.is_sitting = false    
            return clonedState    
        end)    
    end    
  
    local function setPlayerState(id)    
        updateData('state_manager', function(state)    
            local clonedState = table.clone(state)    
            clonedState.states = { { id = id } }    
            clonedState.is_sitting = true    
            return clonedState    
        end)    
    end    
  
    local function removePetState(uniqueId)    
        local pet = pets[uniqueId]    
        if not pet then return end    
        if not pet.model then return end    
        updateData('pet_state_managers', function(petStates)    
            local index = findIndex(petStates, function(state)    
                return state.char == pet.model    
            end)    
            if not index then return petStates end    
            table.remove(petStates, index)    
            return petStates    
        end)    
    end    
  
    local function unmount(uniqueId)    
        local pet = pets[uniqueId]    
        if not pet then return end    
        if not pet.model then return end    
        if currentMountTrack then    
            currentMountTrack:Stop()    
            currentMountTrack:Destroy()    
        end    
        local sourceAttachment = pet.model:FindFirstChild('SourceAttachment', true)    
        if sourceAttachment then sourceAttachment:Destroy() end    
        if game.Players.LocalPlayer.Character then    
            for _, descendant in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do    
                if descendant:IsA('BasePart') and descendant:GetAttribute('HaveMass') then    
                    descendant.Massless = false    
                end    
            end    
        end    
        clearPetState(uniqueId)    
        clearPlayerState()    
        pet.model:ScaleTo(1)    
        mountedPet = nil    
    end    
  
    local function mount(uniqueId, playerState, petState)    
        local pet = pets[uniqueId]    
        if not pet then return end    
        if not pet.model then return end    
        local player = game.Players.LocalPlayer    
        if not player.Character then return end    
        if not player.Character.PrimaryPart then return end    
        mountedPet = uniqueId    
        setPetState(uniqueId, petState)    
        setPlayerState(playerState)    
        pet.model:ScaleTo(2)    
        attachPlayerToPet(pet.model)    
        currentMountTrack = player.Character.Humanoid.Animator:LoadAnimation(    
            animationManager.get_track('PlayerRidingPet')    
        )    
        player.Character.Humanoid.Sit = true    
        for _, descendant in pairs(player.Character:GetDescendants()) do    
            if descendant:IsA('BasePart') and descendant.Massless == false then    
                descendant.Massless = true    
                descendant:SetAttribute('HaveMass', true)    
            end    
        end    
        currentMountTrack:Play()    
    end    
  
    local function fly(uniqueId)    
        mount(uniqueId, 'PlayerFlyingPet', 'PetBeingFlown')    
    end    
  
    local function ride(uniqueId)    
        mount(uniqueId, 'PlayerRidingPet', 'PetBeingRidden')    
    end    
  
    local function unequip(item)    
        local pet = pets[item.unique]    
        if not pet then return end    
        if not pet.model then return end    
        unmount(item.unique)    
        removePetWrapper(item.unique)    
        removePetState(item.unique)    
        pet.model:Destroy()    
        pet.model = nil    
        equippedPet = nil    
        cachedAilments[item.unique] = nil    
        task.defer(function()    
            task.wait(0.15)    
            AilmentsClient.on_ailments_changed(game.Players.LocalPlayer)    
        end)    
    end    
  
    local function equip(item)    
        if item.category == 'pets' then    
            if equippedPet then unequip(equippedPet) end    
            local petModel = getPetModel(item.kind):Clone()    
            petModel.Parent = workspace    
            pets[item.unique].model = petModel    
            if item.properties.neon or item.properties.mega_neon then    
                neonify(petModel, items[item.kind])    
            end    
            equippedPet = item    
            addPetWrapper({    
                char = petModel,    
                mega_neon = item.properties.mega_neon,    
                neon = item.properties.neon,    
                player = game.Players.LocalPlayer,    
                entity_controller = game.Players.LocalPlayer,    
                controller = game.Players.LocalPlayer,    
                rp_name = item.properties.rp_name or '',    
                pet_trick_level = item.properties.pet_trick_level,    
                pet_unique = item.unique,    
                pet_id = item.id,    
                location = {    
                    full_destination_id = 'housing',    
                    destination_id = 'housing',    
                    house_owner = game.Players.LocalPlayer,    
                },    
                pet_progression = {    
                    age = item.properties.age or math.random(1, 6),    
                    percentage = math.random(0, 99) / 100,    
                },    
                are_colors_sealed = false,    
                is_pet = true,    
            })    
            addPetState({    
                char = petModel,    
                player = game.Players.LocalPlayer,    
                store_key = 'pet_state_managers',    
                is_sitting = false,    
                chars_connected_to_me = {},    
                states = {},    
            })    
            task.spawn(function()    
                task.wait(0.3)    
                AilmentsClient.on_ailments_changed(game.Players.LocalPlayer)    
                task.wait(0.5)    
                AilmentsClient.on_ailments_changed(game.Players.LocalPlayer)    
            end)    
        else    
            return oldGet('ToolAPI/Equip'):InvokeServer(item.unique)    
        end    
    end    
  
    local oldGet = router.get    
  
    local function createRemoteFunctionMock(callback)    
        return { InvokeServer = function(_, ...) return callback(...) end }    
    end    
  
    local function createRemoteEventMock(callback)    
        return { FireServer = function(_, ...) return callback(...) end }    
    end    
  
    local equipRemote = createRemoteFunctionMock(function(uniqueId, metadata)    
        local pet = pets[uniqueId]    
        if pet then    
            equip(pet.data)    
            return true, { action = 'equip', is_server = true }    
        end    
        return oldGet('ToolAPI/Equip'):InvokeServer(uniqueId, metadata)    
    end)    
  
    local unequipRemote = createRemoteFunctionMock(function(uniqueId)    
        local pet = pets[uniqueId]    
        if pet then    
            unequip(pet.data)    
            return true, { action = 'unequip', is_server = true }    
        end    
        return oldGet('ToolAPI/Unequip'):InvokeServer(uniqueId)    
    end)    
  
    local rideRemote = createRemoteFunctionMock(function(item) ride(item.pet_unique) end)    
    local flyRemote = createRemoteFunctionMock(function(item) fly(item.pet_unique) end)    
    local unmountRemoteFunction = createRemoteFunctionMock(function()    
        unmount(mountedPet) end)    
    local unmountRemoteEvent = createRemoteEventMock(function() unmount(mountedPet)    
    end)    
  
    router.get = function(name)    
        if name == 'ToolAPI/Equip' then return equipRemote    
        elseif name == 'ToolAPI/Unequip' then return unequipRemote    
        elseif name == 'AdoptAPI/RidePet' then return rideRemote    
        elseif name == 'AdoptAPI/FlyPet' then return flyRemote    
        elseif name == 'AdoptAPI/ExitSeatStatesYield' then return unmountRemoteFunction    
        elseif name == 'AdoptAPI/ExitSeatStates' then return unmountRemoteEvent    
        end    
        return oldGet(name)    
    end    
  
    for _, charWrapper in pairs(clientData.get('pet_char_wrappers')) do    
        oldGet('ToolAPI/Unequip'):InvokeServer(charWrapper.pet_unique)    
    end    
  
    local Loads = require(game.ReplicatedStorage.Fsys).load    
    local InventoryDB = Loads('InventoryDB')    
  
    function GetPetByName(name)    
        for i, v in pairs(InventoryDB.pets) do    
            if v.name:lower() == name:lower() then return v.id end    
        end    
        return false    
    end    
  
    function GetToyByName(name)    
        for i, v in pairs(InventoryDB.toys) do    
            if v.name:lower() == name:lower() then return v.id end    
        end    
        return false    
    end    
  
    -- UI Setup    
    local screenGui = Instance.new('ScreenGui')    
    screenGui.Name = 'SkaiAdmSpawner'    
    screenGui.Parent = LocalPlayer:WaitForChild('PlayerGui')    
  
    local mainFrame = Instance.new('Frame')    
    mainFrame.Size = UDim2.new(0, 320, 0, 441)    
    mainFrame.Position = UDim2.new(0.5, -160, 0.4, -150)    
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)    
    mainFrame.BackgroundTransparency = 1    
    mainFrame.BorderSizePixel = 0    
    mainFrame.ZIndex = 1    
    mainFrame.Parent = screenGui    
  
    local uiCorner = Instance.new('UICorner')    
    uiCorner.CornerRadius = UDim.new(0, 10)    
    uiCorner.Parent = mainFrame    
  
    local uiStroke = Instance.new('UIStroke')    
    uiStroke.Color = Color3.fromRGB(170, 0, 255)    
    uiStroke.Thickness = 3    
    uiStroke.Transparency = 0    
    uiStroke.Parent = mainFrame    
  
    local blackFrame = Instance.new('Frame')    
    blackFrame.Size = UDim2.new(0, 330, 0, 441)    
    blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)    
    blackFrame.BackgroundTransparency = 0    
    blackFrame.BorderSizePixel = 0    
    blackFrame.ZIndex = 0    
    blackFrame.Parent = screenGui    
  
    local blackCorner = Instance.new('UICorner')    
    blackCorner.CornerRadius = UDim.new(0, 15.5)    
    blackCorner.Parent = blackFrame    
  
    mainFrame:GetPropertyChangedSignal('Position'):Connect(function()    
        blackFrame.Position = UDim2.new(    
            mainFrame.Position.X.Scale,    
            mainFrame.Position.X.Offset - 5,    
            mainFrame.Position.Y.Scale,    
            mainFrame.Position.Y.Offset - 5    
        )    
    end)    
    blackFrame.Position = UDim2.new(    
        mainFrame.Position.X.Scale,    
        mainFrame.Position.X.Offset - 5,    
        mainFrame.Position.Y.Scale,    
        mainFrame.Position.Y.Offset - 5    
    )    
  
    local colorPalette = {    
        Color3.fromRGB(170, 0, 255),    
        Color3.fromRGB(120, 0, 255),    
        Color3.fromRGB(0, 100, 255),    
        Color3.fromRGB(0, 200, 255),    
        Color3.fromRGB(0, 255, 150),    
        Color3.fromRGB(0, 255, 100),    
        Color3.fromRGB(255, 100, 0),    
        Color3.fromRGB(255, 50, 150),    
    }    
  
    local TRANSITION_TIME = 4    
    local currentIndex = 1    
  
    local function animateToNextColor()    
        local nextIndex = currentIndex % #colorPalette + 1    
        TweenService:Create(uiStroke, TweenInfo.new(TRANSITION_TIME,    
            Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Color = colorPalette[nextIndex] }):Play()    
        currentIndex = nextIndex    
        wait(TRANSITION_TIME)    
        animateToNextColor()    
    end    
    coroutine.wrap(animateToNextColor)()    
  
    local titleLabel = Instance.new('TextLabel')    
    titleLabel.Size = UDim2.new(1, 0, 0, 25)    
    titleLabel.Position = UDim2.new(0, 0, 0, 37)    
    titleLabel.BackgroundTransparency = 1    
    titleLabel.Text = '9rbp and h2jg dc'    
    titleLabel.Font = Enum.Font.FredokaOne    
    titleLabel.TextSize = 20    
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)    
    titleLabel.Parent = mainFrame    
  
    local tabFrame = Instance.new('Frame')    
    tabFrame.Size = UDim2.new(1, 0, 0, 30)    
    tabFrame.BackgroundTransparency = 1    
    tabFrame.Parent = mainFrame    
  
    local petTab = Instance.new('TextButton')    
    petTab.Size = UDim2.new(0.25, 0, 1, 0)    
    petTab.Position = UDim2.new(0, 0, 0, 0)    
    petTab.Text = 'Pets'    
    petTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)    
    petTab.BackgroundTransparency = 0.1    
    petTab.Font = Enum.Font.FredokaOne    
    petTab.TextColor3 = Color3.fromRGB(255, 255, 255)    
    petTab.TextSize = 16    
    petTab.Parent = tabFrame    
  
    local eggTab = Instance.new('TextButton')    
    eggTab.Size = UDim2.new(0.25, 0, 1, 0)    
    eggTab.Position = UDim2.new(0.25, 0, 0, 0)    
    eggTab.Text = 'Eggs'    
    eggTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)    
    eggTab.BackgroundTransparency = 0.1    
    eggTab.Font = Enum.Font.FredokaOne    
    eggTab.TextColor3 = Color3.fromRGB(255, 255, 255)    
    eggTab.TextSize = 16    
    eggTab.Parent = tabFrame    
  
    local toyTab = Instance.new('TextButton')    
    toyTab.Size = UDim2.new(0.25, 0, 1, 0)    
    toyTab.Position = UDim2.new(0.5, 0, 0, 0)    
    toyTab.Text = 'Toys'    
    toyTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)    
    toyTab.BackgroundTransparency = 0.1    
    toyTab.Font = Enum.Font.FredokaOne    
    toyTab.TextColor3 = Color3.fromRGB(255, 255, 255)    
    toyTab.TextSize = 16    
    toyTab.Parent = tabFrame    
  
    local tabCorner = Instance.new('UICorner')    
    tabCorner.CornerRadius = UDim.new(0, 6)    
    tabCorner.Parent = petTab    
    tabCorner:Clone().Parent = toyTab    
    tabCorner:Clone().Parent = eggTab    
  
    local tabStroke = Instance.new('UIStroke')    
    tabStroke.Color = Color3.fromRGB(255, 255, 255)    
    tabStroke.Thickness = 1.5    
    tabStroke.Transparency = 0.1    
    tabStroke.Parent = petTab    
    tabStroke:Clone().Parent = toyTab    
    tabStroke:Clone().Parent = eggTab    
  
    local tabTextStroke = Instance.new('UIStroke')    
    tabTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
    tabTextStroke.Color = Color3.new(0, 0, 0)    
    tabTextStroke.Thickness = 1.5    
    tabTextStroke.Transparency = 0    
    tabTextStroke.Parent = petTab    
    tabTextStroke:Clone().Parent = toyTab    
    tabTextStroke:Clone().Parent = eggTab    
  
    -- Content frames    
    local petContent = Instance.new('Frame')    
    petContent.Size = UDim2.new(1, 0, 1, -55)    
    petContent.Position = UDim2.new(0, 0, 0, 55)    
    petContent.BackgroundTransparency = 1    
    petContent.Visible = true    
    petContent.Parent = mainFrame    
  
    local toyContent = Instance.new('Frame')    
    toyContent.Size = UDim2.new(1, 0, 1, -55)    
    toyContent.Position = UDim2.new(0, 0, 0, 55)    
    toyContent.BackgroundTransparency = 1    
    toyContent.Visible = false    
    toyContent.Parent = mainFrame    
  
    local eggContent = Instance.new('Frame')    
    eggContent.Size = UDim2.new(1, 0, 1, -55)    
    eggContent.Position = UDim2.new(0, 0, 0, 55)    
    eggContent.BackgroundTransparency = 1    
    eggContent.Visible = false    
    eggContent.Parent = mainFrame    
  
    -- Tab switching (defined early, extended later for tricks)    
    local trickContent -- forward declare    
    local trickTab -- forward declare    
  
    local function switchTab(tab)    
        petContent.Visible = tab == 'pets'    
        toyContent.Visible = tab == 'toys'    
        eggContent.Visible = tab == 'eggs'    
        if trickContent then trickContent.Visible = tab == 'tricks' end    
        petTab.BackgroundColor3 = tab == 'pets' and Color3.fromRGB(80,80,100) or    
            Color3.fromRGB(60,60,80)    
        toyTab.BackgroundColor3 = tab == 'toys' and Color3.fromRGB(80,80,100) or    
            Color3.fromRGB(60,60,80)    
        eggTab.BackgroundColor3 = tab == 'eggs' and Color3.fromRGB(80,80,100) or    
            Color3.fromRGB(60,60,80)    
        if trickTab then trickTab.BackgroundColor3 = tab == 'tricks' and    
            Color3.fromRGB(80,80,100) or Color3.fromRGB(60,60,80) end    
    end    
  
    petTab.MouseButton1Click:Connect(function() switchTab('pets') end)    
    toyTab.MouseButton1Click:Connect(function() switchTab('toys') end)    
    eggTab.MouseButton1Click:Connect(function() switchTab('eggs') end)    
    switchTab('pets')    
  
    -- ****────────────────────────────────────────****    
    -- PET CONTENT    
    -- ****────────────────────────────────────────****    
  
    local petNameBox = Instance.new('TextBox')    
    petNameBox.Size = UDim2.new(0.85, 0, 0, 28)    
    petNameBox.Position = UDim2.new(0.075, 0, 0, 6)    
    petNameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)    
    petNameBox.BackgroundTransparency = 0.2    
    petNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)    
    petNameBox.TextSize = 14    
    petNameBox.Font = Enum.Font.FredokaOne    
    petNameBox.PlaceholderText = 'Enter Pet Name to Spawn'    
    petNameBox.Text = ''    
    petNameBox.ClearTextOnFocus = false    
    petNameBox.Parent = petContent    
  
    local boxCorner = Instance.new('UICorner')    
    boxCorner.CornerRadius = UDim.new(0, 6)    
    boxCorner.Parent = petNameBox    
  
    local textStroke = Instance.new('UIStroke')    
    textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
    textStroke.Color = Color3.new(0, 0, 0)    
    textStroke.Thickness = 1.2    
    textStroke.Transparency = 0    
    textStroke.Parent = petNameBox    
  
    local boxGlow = Instance.new('UIStroke')    
    boxGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
    boxGlow.Color = Color3.fromRGB(255, 255, 255)    
    boxGlow.Thickness = 2.2    
    boxGlow.Transparency = 0.25    
    boxGlow.Parent = petNameBox    
  
    local validPetNames = {}    
    local validPetNamesClean = {}    
  
    local function loadPetNames()    
        local inventory_db = require(game.ReplicatedStorage.Fsys).load('InventoryDB')    
        for category_name, category_table in pairs(inventory_db) do    
            if category_name == 'pets' then    
                for id, item in pairs(category_table) do    
                    validPetNames[#validPetNames + 1] = item.name    
                    validPetNamesClean[#validPetNamesClean + 1] = item.name:lower():gsub('%s+', '')    
                end    
                break    
            end    
        end    
    end    
    loadPetNames()    
  
    local COLORS = {    
        NEUTRAL = Color3.fromRGB(220, 220, 255),    
        VALID = Color3.fromRGB(120, 255, 150),    
        INVALID = Color3.fromRGB(255, 120, 120),    
    }    
  
    local currentColorTween = nil    
  
    local function capitalizeWords(str)    
        local result = ''    
        local i = 1    
        local n = #str    
        while i <= n do    
            if str:sub(i, i):match('%S') then    
                local wordStart = i    
                while i <= n and str:sub(i, i):match('%S') do i = i + 1 end    
                local word = str:sub(wordStart, i - 1)    
                if #word > 0 then word = word:sub(1, 1):upper() .. word:sub(2):lower() end    
                result = result .. word    
            else    
                result = result .. str:sub(i, i)    
                i = i + 1    
            end    
        end    
        return result    
    end    
  
    local lastCursorPosition = 1    
  
    local function setGlowColor(targetColor)    
        if currentColorTween then currentColorTween:Cancel() end    
        currentColorTween = TweenService:Create(    
            boxGlow,    
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),    
            { Color = targetColor }    
        )    
        currentColorTween:Play()    
    end    
  
    petNameBox:GetPropertyChangedSignal('Text'):Connect(function()    
        lastCursorPosition = petNameBox.CursorPosition    
        local inputText = petNameBox.Text    
        local newText = capitalizeWords(inputText)    
        if newText ~= inputText then    
            petNameBox.Text = newText    
            local addedChars = #newText - #inputText    
            petNameBox.CursorPosition = math.max(1, math.min(lastCursorPosition + addedChars, #newText + 1))    
            return    
        end    
        local displayedText = petNameBox.Text    
        local cleanName = displayedText:lower():gsub('%s+', '')    
        local isExactMatch = false    
        local isCleanMatch = false    
        for _, name in ipairs(validPetNames) do    
            if name:lower() == displayedText:lower() then isExactMatch = true; break end    
        end    
        isCleanMatch = table.find(validPetNamesClean, cleanName) ~= nil    
        local targetColor    
        if displayedText == '' then targetColor = COLORS.NEUTRAL    
        elseif isExactMatch then targetColor = COLORS.VALID    
        elseif isCleanMatch then targetColor = COLORS.VALID    
        else targetColor = COLORS.INVALID end    
        setGlowColor(targetColor)    
    end)    
    setGlowColor(COLORS.NEUTRAL)    
  
    local highTierPets = {    
        'Shadow Dragon','Giant Panda','Cryptid','Bat Dragon','Frost Dragon',    
        'Giraffe','Owl','Parrot','Crow','Evil Unicorn','Arctic Reindeer',    
        'Hedgehog','Dalmatian','Turtle','Kangaroo','Lion','Elephant','Rhino',    
        'Chocolate Chip Bat Dragon','Cow','Blazing Lion','African Wild Dog',    
        'Flamingo','Diamond Butterfly','Mini Pig','Caterpillar','Albino Monkey',    
        'Candyfloss Chick','Pelican','Blue Dog','Pink Cat','Haetae',    
        'Peppermint Penguin','Winged Tiger','Sugar Glider','Shark Puppy','Goat',    
        'Sheeeeep','Lion Cub','Nessie','Flamingo','Frostbite Bear',    
        'Balloon Unicorn','Honey Badger','Hot Doggo','Crocodile','Hare','Ram',    
        'Yeti','Meetkat','Jellyfish','Happy Clown','Orchid Butterfly',    
        'Many Mackerel','Strawberry Shortcake Bat Dragon','Zombie Buffalo',    
        'Fairy Bat Dragon',    
    }    
  
    local highTierButton = Instance.new('TextButton')    
    highTierButton.Size = UDim2.new(0.6, 0, 0, 25)    
    highTierButton.Position = UDim2.new(0.2, 0, 0, 133)    
    highTierButton.Text = 'Spawn High Tier'    
    highTierButton.BackgroundColor3 = Color3.fromRGB(200, 0, 200)    
    highTierButton.BackgroundTransparency = 0.1    
    highTierButton.Font = Enum.Font.FredokaOne    
    highTierButton.TextColor3 = Color3.fromRGB(255, 255, 255)    
    highTierButton.TextSize = 16    
    highTierButton.Parent = petContent    
  
    local highTierCorner = Instance.new('UICorner')    
    highTierCorner.CornerRadius = UDim.new(0, 8)    
    highTierCorner.Parent = highTierButton    
  
    local highTierStroke = Instance.new('UIStroke')    
    highTierStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
    highTierStroke.Color = Color3.fromRGB(255, 255, 255)    
    highTierStroke.Thickness = 1.5    
    highTierStroke.Transparency = 0.1    
    highTierStroke.Parent = highTierButton    
  
    local highTierTextStroke = Instance.new('UIStroke')    
    highTierTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
    highTierTextStroke.Color = Color3.new(0, 0, 0)    
    highTierTextStroke.Thickness = 1.5    
    highTierTextStroke.Transparency = 0    
    highTierTextStroke.Parent = highTierButton    
  
    local highTierOriginalProperties = {    
        BackgroundColor3 = highTierButton.BackgroundColor3,    
        BackgroundTransparency = highTierButton.BackgroundTransparency,    
        StrokeColor = Color3.fromRGB(255, 255, 255),    
        StrokeThickness = 1.5,    
        StrokeTransparency = 0.1,    
    }    
    local highTierActiveAnimation = { endTime = 0, tween = nil, resetTween = nil }    
  
    highTierButton.MouseEnter:Connect(function()    
        if highTierActiveAnimation.endTime < os.clock() then    
            highTierButton.BackgroundColor3 = Color3.fromRGB(220, 0, 220)    
            TweenService:Create(highTierStroke, TweenInfo.new(0.2), { Thickness = 2, Transparency = 0.05 }):Play()    
        end    
    end)    
  
    highTierButton.MouseLeave:Connect(function()    
        if highTierActiveAnimation.endTime < os.clock() then    
            highTierButton.BackgroundColor3 = highTierOriginalProperties.BackgroundColor3    
            TweenService:Create(highTierStroke, TweenInfo.new(0.2), {    
                Thickness = highTierOriginalProperties.StrokeThickness,    
                Transparency = highTierOriginalProperties.StrokeTransparency,    
            }):Play()    
        end    
    end)    
  
    local selectedAge = nil    
  
    highTierButton.MouseButton1Click:Connect(function()    
        local currentTime = os.clock()    
        local extendDuration = 1.5    
        local isExtension = currentTime < highTierActiveAnimation.endTime    
        if isExtension then    
            highTierActiveAnimation.intensity = math.min(highTierActiveAnimation.intensity + 0.3, 1.5)    
        else    
            highTierActiveAnimation.intensity = 1.0    
        end    
        if highTierActiveAnimation.strokeTween then highTierActiveAnimation.strokeTween:Cancel() end    
        if highTierActiveAnimation.resetThread then coroutine.close(highTierActiveAnimation.resetThread) end    
        local feedbackColor = Color3.fromRGB(255, 50, 50)    
        local spawnSuccess = false    
        for _, petName in ipairs(highTierPets) do    
            local petId = GetPetByName(petName)    
            if petId then    
                if activeFlags['M'] then    
                    createPet(petId, { pet_trick_level=math.random(1,5), mega_neon=true,    
                        rideable=activeFlags['R'], flyable=activeFlags['F'], age=selectedAge or math.random(1,6),    
                        ailments_completed=0, rp_name='' })    
                elseif activeFlags['N'] then    
                    createPet(petId, { pet_trick_level=math.random(0,5), neon=true,    
                        rideable=activeFlags['R'], flyable=activeFlags['F'], age=selectedAge or math.random(1,6),    
                        ailments_completed=0, rp_name='' })    
                else    
                    createPet(petId, { pet_trick_level=math.random(1,5), neon=false, mega_neon=false,    
                        rideable=activeFlags['R'], flyable=activeFlags['F'], age=selectedAge or math.random(1,6),    
                        ailments_completed=0, rp_name='' })    
                end    
                spawnSuccess = true    
            end    
        end    
        if spawnSuccess then    
            feedbackColor = Color3.fromRGB(0, 255 * highTierActiveAnimation.intensity, 0)    
            game.StarterGui:SetCore('SendNotification', { Title='High Tier Pets Spawned!', Text='All high tier pets have been spawned!', Duration=5 })    
        else    
            game.StarterGui:SetCore('SendNotification', { Title='Error', Text='Failed to spawn high tier pets!', Duration=3 })    
        end    
        highTierStroke.Color = feedbackColor    
        highTierStroke.Thickness = 2 * highTierActiveAnimation.intensity    
        highTierStroke.Transparency = 0.1 / highTierActiveAnimation.intensity    
        highTierActiveAnimation.endTime = currentTime + extendDuration    
        highTierActiveAnimation.resetThread = task.delay(extendDuration, function()    
            if os.clock() >= highTierActiveAnimation.endTime then    
                TweenService:Create(highTierStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {    
                    Color = highTierOriginalProperties.StrokeColor,    
                    Thickness = highTierOriginalProperties.StrokeThickness,    
                    Transparency = highTierOriginalProperties.StrokeTransparency,    
                }):Play()    
            end    
        end)    
    end)    
  
    local startButton = Instance.new('TextButton')    
    startButton.Size = UDim2.new(0.6, 0, 0, 25)    
    startButton.Position = UDim2.new(0.2, 0, 0, 110)    
    startButton.Text = 'Spawn Pet'    
    startButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)    
    startButton.BackgroundTransparency = 0.1    
    startButton.Font = Enum.Font.FredokaOne    
    startButton.TextColor3 = Color3.fromRGB(255, 255, 255)    
    startButton.TextSize = 16    
    startButton.Parent = petContent    
  
    local buttonCorner = Instance.new('UICorner')    
    buttonCorner.CornerRadius = UDim.new(0, 8)    
    buttonCorner.Parent = startButton    
  
    local buttonStroke = Instance.new('UIStroke')    
    buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
    buttonStroke.Color = Color3.fromRGB(255, 255, 255)    
    buttonStroke.Thickness = 1.5    
    buttonStroke.Transparency = 0.1    
    buttonStroke.Parent = startButton    
  
    local textStroke2 = Instance.new('UIStroke')    
    textStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
    textStroke2.Color = Color3.new(0, 0, 0)    
    textStroke2.Thickness = 1.5    
    textStroke2.Transparency = 0    
    textStroke2.Parent = startButton    
  
    local originalProperties = {    
        BackgroundColor3 = startButton.BackgroundColor3,    
        BackgroundTransparency = startButton.BackgroundTransparency,    
        StrokeColor = Color3.fromRGB(255, 255, 255),    
        StrokeThickness = 1.5,    
        StrokeTransparency = 0.1,    
    }    
    local activeAnimation = { endTime=0, strokeTween=nil, resetThread=nil, intensity=1.0, lastSuccess=false }    
  
    startButton.MouseEnter:Connect(function()    
        if activeAnimation.endTime < os.clock() then    
            startButton.BackgroundColor3 = Color3.fromRGB(0, 130, 230)    
            TweenService:Create(buttonStroke, TweenInfo.new(0.2), { Thickness=2, Transparency=0.05 }):Play()    
        end    
    end)    
  
    startButton.MouseLeave:Connect(function()    
        if activeAnimation.endTime < os.clock() then    
            startButton.BackgroundColor3 = originalProperties.BackgroundColor3    
            TweenService:Create(buttonStroke, TweenInfo.new(0.2), {    
                Thickness = originalProperties.StrokeThickness,    
                Transparency = originalProperties.StrokeTransparency,    
            }):Play()    
        end    
    end)    
  
    _G.spawn_pet = nil    
  
    startButton.MouseButton1Click:Connect(function()    
        local pet_name = petNameBox.Text    
        local currentTime = os.clock()    
        local extendDuration = 1.5    
        local isExtension = currentTime < activeAnimation.endTime    
        if isExtension then activeAnimation.intensity = math.min(activeAnimation.intensity + 0.3, 1.5)    
        else activeAnimation.intensity = 1.0 end    
        if activeAnimation.strokeTween then activeAnimation.strokeTween:Cancel() end    
        if activeAnimation.resetThread then coroutine.close(activeAnimation.resetThread) end    
        local feedbackColor = Color3.fromRGB(255, 50, 50)    
        local spawnSuccess = false    
        if pet_name ~= '' then    
            local petId = GetPetByName(pet_name)    
            if petId then    
                if activeFlags['M'] then    
                    createPet(petId, { pet_trick_level=math.random(1,5), mega_neon=true,    
                        rideable=activeFlags['R'], flyable=activeFlags['F'], age=selectedAge or math.random(1,6),    
                        ailments_completed=0, rp_name='' })    
                elseif activeFlags['N'] then    
                    createPet(petId, { pet_trick_level=math.random(0,5), neon=true,    
                        rideable=activeFlags['R'], flyable=activeFlags['F'], age=selectedAge or math.random(1,6),    
                        ailments_completed=0, rp_name='' })    
                else    
                    createPet(petId, { pet_trick_level=math.random(1,5), neon=false, mega_neon=false,    
                        rideable=activeFlags['R'], flyable=activeFlags['F'], age=selectedAge or math.random(1,6),    
                        ailments_completed=0, rp_name='' })    
                end    
                spawnSuccess = true    
                game.StarterGui:SetCore('SendNotification', { Title='Pet Spawned!', Text=pet_name..' has been spawned!', Duration=5 })    
            else    
                game.StarterGui:SetCore('SendNotification', { Title='Error', Text='Pet not found: '..pet_name, Duration=3 })    
            end    
        else    
            game.StarterGui:SetCore('SendNotification', { Title='Error', Text='Please enter a pet name!', Duration=3 })    
        end    
        activeAnimation.lastSuccess = spawnSuccess    
        if isExtension and activeAnimation.lastSuccess then    
            feedbackColor = Color3.fromRGB(0, 255 * activeAnimation.intensity, 0)    
        end    
        buttonStroke.Color = feedbackColor    
        buttonStroke.Thickness = 2 * activeAnimation.intensity    
        buttonStroke.Transparency = 0.1 / activeAnimation.intensity    
        if isExtension then    
            activeAnimation.strokeTween = TweenService:Create(buttonStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {    
                Thickness = 2.5 * activeAnimation.intensity,    
                Transparency = 0.05 / activeAnimation.intensity,    
            })    
            activeAnimation.strokeTween:Play()    
        end    
        activeAnimation.endTime = currentTime + extendDuration    
        activeAnimation.resetThread = task.delay(extendDuration, function()    
            if os.clock() >= activeAnimation.endTime then    
                TweenService:Create(buttonStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {    
                    Color = originalProperties.StrokeColor,    
                    Thickness = originalProperties.StrokeThickness,    
                    Transparency = originalProperties.StrokeTransparency,    
                }):Play()    
            end    
        end)    
    end)    
  
    local infoBox = Instance.new('Frame')    
    infoBox.Name = 'InfoBox'    
    infoBox.Size = UDim2.new(0.85, 0, 0, 30)    
    infoBox.Position = UDim2.new(0.075, 0, 0, 44)    
    infoBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)    
    infoBox.BackgroundTransparency = 0.5    
    infoBox.BorderSizePixel = 0    
    infoBox.Parent = petContent    
  
    local infoBoxCorner = Instance.new('UICorner')    
    infoBoxCorner.CornerRadius = UDim.new(0, 8)    
    infoBoxCorner.Parent = infoBox    
  
    local infoBoxStroke = Instance.new('UIStroke')    
    infoBoxStroke.Color = Color3.fromRGB(255, 255, 255)    
    infoBoxStroke.Thickness = 1.2    
    infoBoxStroke.Transparency = 0.7    
    infoBoxStroke.Parent = infoBox    
  
    local infoTextContainer = Instance.new('Frame')    
    infoTextContainer.Name = 'TextContainer'    
    infoTextContainer.Size = UDim2.new(1, 0, 1, 0)    
    infoTextContainer.BackgroundTransparency = 1    
    infoTextContainer.Parent = infoBox    
  
    local uiListLayout = Instance.new('UIListLayout')    
    uiListLayout.FillDirection = Enum.FillDirection.Horizontal    
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center    
    uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center    
    uiListLayout.Padding = UDim.new(0, 4)    
    uiListLayout.Parent = infoTextContainer    
  
    local baseColorsMap = {    
        M = Color3.fromRGB(170, 0, 255),    
        N = Color3.fromRGB(0, 255, 100),    
        F = Color3.fromRGB(0, 200, 255),    
        R = Color3.fromRGB(255, 50, 150),    
    }    
  
    local animationSystem = {    
        pulsePhase = 0, pulseSpeed = 2,    
        baseThickness = 1.2, maxThickness = 3,    
        activeColors = nil, active = false,    
    }    
  
    local function updateAnimation(dt)    
        if not animationSystem.active then return end    
        animationSystem.pulsePhase = animationSystem.pulsePhase + dt * animationSystem.pulseSpeed    
        local pulse = (math.sin(animationSystem.pulsePhase) + 1) * 0.5    
        local thickness = animationSystem.baseThickness + (animationSystem.maxThickness - animationSystem.baseThickness) * pulse    
        infoBoxStroke.Thickness = thickness    
        infoBoxStroke.Transparency = 0.7 - (0.5 * pulse)    
        if animationSystem.activeColors then    
            local brightness = 0.8 + (0.4 * pulse)    
            local r, g, b = 0, 0, 0    
            for _, color in ipairs(animationSystem.activeColors) do    
                r = r + (color.R * brightness)    
                g = g + (color.G * brightness)    
                b = b + (color.B * brightness)    
            end    
            infoBoxStroke.Color = Color3.new(    
                math.min(r / #animationSystem.activeColors, 1),    
                math.min(g / #animationSystem.activeColors, 1),    
                math.min(b / #animationSystem.activeColors, 1)    
            )    
        end    
    end    
  
    local function createTextLabel(text, color)    
        local label = Instance.new('TextLabel')    
        label.Size = UDim2.new(0, 0, 1, 0)    
        label.AutomaticSize = Enum.AutomaticSize.X    
        label.BackgroundTransparency = 1    
        label.Text = text    
        label.Font = Enum.Font.FredokaOne    
        label.TextSize = 16    
        label.TextColor3 = color    
        label.TextXAlignment = Enum.TextXAlignment.Left    
        label.TextYAlignment = Enum.TextYAlignment.Center    
        if text == 'Mega Neon' then label.Text = 'Mega Neon'    
        elseif text ~= 'Ride' and text ~= 'Neon' and text ~= 'Fly' then label.Text = label.Text .. ' '    
        end    
        return label    
    end    
  
    local function updateInfoBox(flags)    
        for _, child in ipairs(infoTextContainer:GetChildren()) do    
            if child:IsA('TextLabel') then child:Destroy() end    
        end    
        local activeColors = {}    
        local hasFlags = false    
        local labels = {}    
        if flags['M'] then table.insert(labels, {'Mega Neon', baseColorsMap.M}); table.insert(activeColors, baseColorsMap.M); hasFlags = true end    
        if flags['N'] then table.insert(labels, {'Neon', baseColorsMap.N}); table.insert(activeColors, baseColorsMap.N); hasFlags = true end    
        if flags['F'] then table.insert(labels, {'Fly', baseColorsMap.F}); table.insert(activeColors, baseColorsMap.F); hasFlags = true end    
        if flags['R'] then table.insert(labels, {'Ride', baseColorsMap.R}); table.insert(activeColors, baseColorsMap.R); hasFlags = true end    
        for _, labelData in ipairs(labels) do    
            createTextLabel(labelData[1], labelData[2]).Parent = infoTextContainer    
        end    
        if hasFlags then    
            animationSystem.active = true    
            animationSystem.activeColors = activeColors    
        else    
            animationSystem.active = false    
            createTextLabel('Normal', Color3.fromRGB(255, 255, 255)).Parent = infoTextContainer    
            infoBoxStroke.Color = Color3.fromRGB(255, 255, 255)    
            infoBoxStroke.Thickness = animationSystem.baseThickness    
            infoBoxStroke.Transparency = 0.7    
        end    
    end    
  
    RunService.Heartbeat:Connect(updateAnimation)    
    updateInfoBox({ F=false, R=false, N=false, M=false })    
  
    local prefixes = { 'F', 'R', 'N', 'M' }    
    local totalButtons = #prefixes    
    local buttonWidth = 0.18    
    local spaceBetweenButtons = 0.07    
    local totalWidth = totalButtons * buttonWidth + (totalButtons - 1) * spaceBetweenButtons    
    local startingX = (1 - totalWidth) / 2    
  
    for i, prefix in ipairs(prefixes) do    
        local prefixButton = Instance.new('TextButton')    
        prefixButton.Size = UDim2.new(buttonWidth, 0, 0, 25)    
        prefixButton.Position = UDim2.new(startingX + (buttonWidth + spaceBetweenButtons) * (i - 1), 0, 0, 77)    
        prefixButton.Text = prefix    
        prefixButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)    
        prefixButton.BackgroundTransparency = 0.2    
        prefixButton.Font = Enum.Font.FredokaOne    
        prefixButton.TextColor3 = Color3.fromRGB(255, 255, 255)    
        prefixButton.TextSize = 16    
        prefixButton.Parent = petContent    
  
        local bCorner = Instance.new('UICorner'); bCorner.CornerRadius = UDim.new(0, 6); bCorner.Parent = prefixButton    
        local bStroke = Instance.new('UIStroke'); bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        bStroke.Color = baseColorsMap[prefix]; bStroke.Thickness = 2; bStroke.Transparency = 0.5; bStroke.Parent = prefixButton    
        local bTextStroke = Instance.new('UIStroke'); bTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        bTextStroke.Color = Color3.new(0,0,0); bTextStroke.Thickness = 1.5; bTextStroke.Transparency = 0; bTextStroke.Parent = prefixButton    
  
        local originalStroke = { Color=baseColorsMap[prefix], Thickness=2, Transparency=0.5 }    
  
        prefixButton.MouseButton1Click:Connect(function()    
            if prefix == 'M' and activeFlags['N'] then return end    
            if prefix == 'N' and activeFlags['M'] then return end    
            activeFlags[prefix] = not activeFlags[prefix]    
            if activeFlags[prefix] then    
                prefixButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)    
                TweenService:Create(bStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad),    
                    { Color=Color3.fromRGB(0,255,0), Thickness=3, Transparency=0.2 }):Play()    
            else    
                prefixButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)    
                TweenService:Create(bStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad),    
                    { Color=originalStroke.Color, Thickness=originalStroke.Thickness, Transparency=originalStroke.Transparency }):Play()    
            end    
            updateInfoBox(activeFlags)    
        end)    
    end    
  
    -- Age selector    
    local NORMAL_AGES = {'Newborn','Junior','Pre-Teen','Teen','Post-Teen','Full Grown'}    
    local NEON_AGES = {'Reborn','Twinkle','Sparkle','Flare','Sunshine','Luminous'}    
  
    local ageBtn = Instance.new('TextButton')    
    ageBtn.Size = UDim2.new(0.85, 0, 0, 26)    
    ageBtn.Position = UDim2.new(0.075, 0, 0, 168)    
    ageBtn.Text = 'Age: Random ▼'    
    ageBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)    
    ageBtn.Font = Enum.Font.FredokaOne    
    ageBtn.TextColor3 = Color3.fromRGB(200, 200, 255)    
    ageBtn.TextSize = 13    
    ageBtn.Parent = petContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = ageBtn    
        local s = Instance.new('UIStroke'); s.Color = Color3.fromRGB(150,130,255); s.Thickness = 1.5; s.Parent = ageBtn    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = ageBtn    
    end    
  
    local ageDrop = Instance.new('Frame')    
    ageDrop.Size = UDim2.new(0.85, 0, 0, 200)    
    ageDrop.Position = UDim2.new(0.075, 0, 0, 198)    
    ageDrop.BackgroundColor3 = Color3.fromRGB(28, 28, 42)    
    ageDrop.BorderSizePixel = 0    
    ageDrop.Visible = false    
    ageDrop.ZIndex = 20    
    ageDrop.ClipsDescendants = true    
    ageDrop.Parent = petContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = ageDrop    
        local s = Instance.new('UIStroke'); s.Color = Color3.fromRGB(150,130,255); s.Thickness = 1.2; s.Parent = ageDrop    
    end    
  
    local ageScroll = Instance.new('ScrollingFrame')    
    ageScroll.Size = UDim2.new(1,-6,1,-6)    
    ageScroll.Position = UDim2.new(0,3,0,3)    
    ageScroll.BackgroundTransparency = 1    
    ageScroll.BorderSizePixel = 0    
    ageScroll.ScrollBarThickness = 4    
    ageScroll.ScrollBarImageColor3 = Color3.fromRGB(150,130,255)    
    ageScroll.ZIndex = 21    
    ageScroll.Parent = ageDrop    
  
    local ageLayout = Instance.new('UIListLayout')    
    ageLayout.SortOrder = Enum.SortOrder.LayoutOrder    
    ageLayout.Padding = UDim.new(0,2)    
    ageLayout.Parent = ageScroll    
  
    local function makeAgeHeader(text)    
        local lbl = Instance.new('TextLabel')    
        lbl.Size = UDim2.new(1,0,0,18)    
        lbl.BackgroundColor3 = Color3.fromRGB(50,40,80)    
        lbl.BackgroundTransparency = 0.3    
        lbl.Text = text    
        lbl.Font = Enum.Font.FredokaOne    
        lbl.TextSize = 11    
        lbl.TextColor3 = Color3.fromRGB(200,180,255)    
        lbl.ZIndex = 22    
        lbl.Parent = ageScroll    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,3); c.Parent = lbl    
        return lbl    
    end    
  
    local ageBtnRefs = {}    
  
    local function makeAgeOption(label, ageValue, order)    
        local b = Instance.new('TextButton')    
        b.Size = UDim2.new(1,0,0,24)    
        b.BackgroundColor3 = Color3.fromRGB(45,45,65)    
        b.BackgroundTransparency = 0.2    
        b.Text = label    
        b.Font = Enum.Font.FredokaOne    
        b.TextSize = 13    
        b.TextColor3 = Color3.fromRGB(210,210,240)    
        b.ZIndex = 22    
        b.LayoutOrder = order    
        b.Parent = ageScroll    
        local bc = Instance.new('UICorner'); bc.CornerRadius = UDim.new(0,4); bc.Parent = b    
        local bp = Instance.new('UIPadding'); bp.PaddingLeft = UDim.new(0,8); bp.Parent = b    
        ageBtnRefs[label] = b    
        b.MouseButton1Click:Connect(function()    
            for _, ob in pairs(ageBtnRefs) do    
                ob.BackgroundColor3 = Color3.fromRGB(45,45,65)    
                ob.TextColor3 = Color3.fromRGB(210,210,240)    
            end    
            selectedAge = ageValue    
            b.BackgroundColor3 = Color3.fromRGB(75,55,115)    
            b.TextColor3 = Color3.fromRGB(200,180,255)    
            ageBtn.Text = label .. ' ▼'    
            ageDrop.Visible = false    
        end)    
        return b    
    end    
  
    local randomAgeBtn = Instance.new('TextButton')    
    randomAgeBtn.Size = UDim2.new(1,0,0,24)    
    randomAgeBtn.BackgroundColor3 = Color3.fromRGB(45,45,65)    
    randomAgeBtn.BackgroundTransparency = 0.2    
    randomAgeBtn.Text = 'Random'    
    randomAgeBtn.Font = Enum.Font.FredokaOne    
    randomAgeBtn.TextSize = 13    
    randomAgeBtn.TextColor3 = Color3.fromRGB(255,220,100)    
    randomAgeBtn.ZIndex = 22    
    randomAgeBtn.LayoutOrder = 0    
    randomAgeBtn.Parent = ageScroll    
    do    
        local bc = Instance.new('UICorner'); bc.CornerRadius = UDim.new(0,4); bc.Parent = randomAgeBtn    
        local bp = Instance.new('UIPadding'); bp.PaddingLeft = UDim.new(0,8); bp.Parent = randomAgeBtn    
    end    
    randomAgeBtn.MouseButton1Click:Connect(function()    
        for _, ob in pairs(ageBtnRefs) do    
            ob.BackgroundColor3 = Color3.fromRGB(45,45,65)    
            ob.TextColor3 = Color3.fromRGB(210,210,240)    
        end    
        selectedAge = nil    
        randomAgeBtn.BackgroundColor3 = Color3.fromRGB(75,55,115)    
        ageBtn.Text = 'Age: Random ▼'    
        ageDrop.Visible = false    
    end)    
  
    makeAgeHeader('****──**** Normal ****──****').LayoutOrder = 1    
    local normalAgeMap = {1,2,3,4,5,6}    
    for i, ageName in ipairs(NORMAL_AGES) do    
        makeAgeOption(ageName, normalAgeMap[i], i + 1)    
    end    
  
    makeAgeHeader('****──**** Neon ****──****').LayoutOrder = 10    
    local neonAgeMap = {7,8,9,10,11,12}    
    for i, ageName in ipairs(NEON_AGES) do    
        makeAgeOption(ageName, neonAgeMap[i], i + 10)    
    end    
  
    ageScroll.CanvasSize = UDim2.new(0,0,0, 1 + 18 + (#NORMAL_AGES*26) + 18 + (#NEON_AGES*26) + 26)    
  
    ageBtn.MouseButton1Click:Connect(function()    
        ageDrop.Visible = not ageDrop.Visible    
        local arrow = ageDrop.Visible and ' ▲' or ' ▼'    
        if selectedAge == nil then ageBtn.Text = 'Age: Random' .. arrow    
        else ageBtn.Text = ageBtn.Text:gsub(' [▲▼]', '') .. arrow end    
    end)    
  
    -- ****────────────────────────────────────────****    
    -- TOY CONTENT    
    -- ****────────────────────────────────────────****    
  
    local toyNameBox = Instance.new('TextBox')    
    toyNameBox.Size = UDim2.new(0.85, 0, 0, 28)    
    toyNameBox.Position = UDim2.new(0.075, 0, 0.1, 0)    
    toyNameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)    
    toyNameBox.BackgroundTransparency = 0.2    
    toyNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)    
    toyNameBox.TextSize = 14    
    toyNameBox.Font = Enum.Font.FredokaOne    
    toyNameBox.PlaceholderText = 'Enter Toy Name to Spawn'    
    toyNameBox.Text = ''    
    toyNameBox.ClearTextOnFocus = false    
    toyNameBox.Parent = toyContent    
  
    local toyBoxCorner = Instance.new('UICorner')    
    toyBoxCorner.CornerRadius = UDim.new(0, 6)    
    toyBoxCorner.Parent = toyNameBox    
  
    local toyTextStroke = Instance.new('UIStroke')    
    toyTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
    toyTextStroke.Color = Color3.new(0, 0, 0)    
    toyTextStroke.Thickness = 1.2    
    toyTextStroke.Transparency = 0    
    toyTextStroke.Parent = toyNameBox    
  
    local toyBoxGlow = Instance.new('UIStroke')    
    toyBoxGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
    toyBoxGlow.Color = Color3.fromRGB(255, 255, 255)    
    toyBoxGlow.Thickness = 2.2    
    toyBoxGlow.Transparency = 0.25    
    toyBoxGlow.Parent = toyNameBox    
  
    local validToyNames = {}    
    local validToyNamesClean = {}    
  
    local function loadToyNames()    
        local inventory_db = require(game.ReplicatedStorage.Fsys).load('InventoryDB')    
        for category_name, category_table in pairs(inventory_db) do    
            if category_name == 'toys' then    
                for id, item in pairs(category_table) do    
                    validToyNames[#validToyNames + 1] = item.name    
                    validToyNamesClean[#validToyNamesClean + 1] = item.name:lower():gsub('%s+', '')    
                end    
                break    
            end    
        end    
    end    
    loadToyNames()    
  
    local toyCurrentColorTween = nil    
  
    toyNameBox:GetPropertyChangedSignal('Text'):Connect(function()    
        lastCursorPosition = toyNameBox.CursorPosition    
        local inputText = toyNameBox.Text    
        local newText = capitalizeWords(inputText)    
        if newText ~= inputText then    
            toyNameBox.Text = newText    
            local addedChars = #newText - #inputText    
            toyNameBox.CursorPosition = math.max(1, math.min(lastCursorPosition + addedChars, #newText + 1))    
            return    
        end    
        local displayedText = toyNameBox.Text    
        local cleanName = displayedText:lower():gsub('%s+', '')    
        local isExactMatch = false    
        for _, name in ipairs(validToyNames) do    
            if name:lower() == displayedText:lower() then isExactMatch = true; break end    
        end    
        local isCleanMatch = table.find(validToyNamesClean, cleanName) ~= nil    
        local targetColor    
        if displayedText == '' then targetColor = COLORS.NEUTRAL    
        elseif isExactMatch then targetColor = COLORS.VALID    
        elseif isCleanMatch then targetColor = COLORS.VALID    
        else targetColor = COLORS.INVALID end    
        if toyCurrentColorTween then toyCurrentColorTween:Cancel() end    
        toyCurrentColorTween = TweenService:Create(toyBoxGlow, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Color=targetColor })    
        toyCurrentColorTween:Play()    
    end)    
  
    if toyCurrentColorTween then toyCurrentColorTween:Cancel() end    
    toyCurrentColorTween = TweenService:Create(toyBoxGlow, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Color=COLORS.NEUTRAL })    
    toyCurrentColorTween:Play()    
  
    local toySpawnButton = Instance.new('TextButton')    
    toySpawnButton.Size = UDim2.new(0.6, 0, 0, 25)    
    toySpawnButton.Position = UDim2.new(0.2, 0, 0.3, 0)    
    toySpawnButton.Text = 'Spawn Toy'    
    toySpawnButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)    
    toySpawnButton.BackgroundTransparency = 0.1    
    toySpawnButton.Font = Enum.Font.FredokaOne    
    toySpawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)    
    toySpawnButton.TextSize = 16    
    toySpawnButton.Parent = toyContent    
  
    local toyButtonCorner = Instance.new('UICorner')    
    toyButtonCorner.CornerRadius = UDim.new(0, 8)    
    toyButtonCorner.Parent = toySpawnButton    
  
    local toyButtonStroke = Instance.new('UIStroke')    
    toyButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
    toyButtonStroke.Color = Color3.fromRGB(255, 255, 255)    
    toyButtonStroke.Thickness = 1.5    
    toyButtonStroke.Transparency = 0.1    
    toyButtonStroke.Parent = toySpawnButton    
  
    local toyTextStroke2 = Instance.new('UIStroke')    
    toyTextStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
    toyTextStroke2.Color = Color3.new(0, 0, 0)    
    toyTextStroke2.Thickness = 1.5    
    toyTextStroke2.Transparency = 0    
    toyTextStroke2.Parent = toySpawnButton    
  
    local toyOriginalProperties = {    
        BackgroundColor3 = toySpawnButton.BackgroundColor3,    
        BackgroundTransparency = toySpawnButton.BackgroundTransparency,    
        StrokeColor = Color3.fromRGB(255, 255, 255),    
        StrokeThickness = 1.5,    
        StrokeTransparency = 0.1,    
    }    
    local toyActiveAnimation = { endTime=0, strokeTween=nil, resetThread=nil, intensity=1.0, lastSuccess=false }    
  
    toySpawnButton.MouseEnter:Connect(function()    
        if toyActiveAnimation.endTime < os.clock() then    
            toySpawnButton.BackgroundColor3 = Color3.fromRGB(220, 120, 0)    
            TweenService:Create(toyButtonStroke, TweenInfo.new(0.2), { Thickness=2, Transparency=0.05 }):Play()    
        end    
    end)    
  
    toySpawnButton.MouseLeave:Connect(function()    
        if toyActiveAnimation.endTime < os.clock() then    
            toySpawnButton.BackgroundColor3 = toyOriginalProperties.BackgroundColor3    
            TweenService:Create(toyButtonStroke, TweenInfo.new(0.2), {    
                Thickness = toyOriginalProperties.StrokeThickness,    
                Transparency = toyOriginalProperties.StrokeTransparency,    
            }):Play()    
        end    
    end)    
  
    toySpawnButton.MouseButton1Click:Connect(function()    
        local HIGH_TOYS = { 'Rainbow Rattle', 'Tombstone Ghostify', 'Flying Broomstick', 'Candy Cannon' }    
        local toyBtnColors = {    
            Color3.fromRGB(255, 100, 180),    
            Color3.fromRGB(100, 220, 255),    
            Color3.fromRGB(255, 180, 50),    
            Color3.fromRGB(255, 120, 60),    
        }    
  
        -- Only create quick buttons once (guard by checking if already exist)    
        if not toyContent:FindFirstChild('HighToyBtn_1') then    
            for i, toyName in ipairs(HIGH_TOYS) do    
                local qBtn = Instance.new('TextButton')    
                qBtn.Name = 'HighToyBtn_' .. i    
                qBtn.Size = UDim2.new(0.85, 0, 0, 24)    
                qBtn.Position = UDim2.new(0.075, 0, 0.55, (i - 1) * 28)    
                qBtn.Text = toyName    
                qBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)    
                qBtn.BackgroundTransparency = 0.1    
                qBtn.Font = Enum.Font.FredokaOne    
                qBtn.TextColor3 = toyBtnColors[i]    
                qBtn.TextSize = 13    
                qBtn.Parent = toyContent    
                do    
                    local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = qBtn    
                    local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
                    s.Color = toyBtnColors[i]; s.Thickness = 1.5; s.Transparency = 0.2; s.Parent = qBtn    
                    local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
                    ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = qBtn    
                end    
                qBtn.MouseEnter:Connect(function()    
                    TweenService:Create(qBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(55,45,75)}):Play()    
                end)    
                qBtn.MouseLeave:Connect(function()    
                    TweenService:Create(qBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(35,35,50)}):Play()    
                end)    
                local capName = toyName    
                qBtn.MouseButton1Click:Connect(function()    
                    local toyId = GetToyByName(capName)    
                    if toyId then    
                        createToy(toyId)    
                        game.StarterGui:SetCore('SendNotification', {Title='Spawned!', Text=capName..' added.', Duration=2})    
                    else    
                        game.StarterGui:SetCore('SendNotification', {Title='Not Found', Text=capName, Duration=3})    
                    end    
                end)    
            end    
  
            local spawnAllBtn = Instance.new('TextButton')    
            spawnAllBtn.Size = UDim2.new(0.85, 0, 0, 28)    
            spawnAllBtn.Position = UDim2.new(0.075, 0, 0.55, #HIGH_TOYS * 28 + 6)    
            spawnAllBtn.Text = 'Spawn High-Level Toys'    
            spawnAllBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 255)    
            spawnAllBtn.BackgroundTransparency = 0.05    
            spawnAllBtn.Font = Enum.Font.FredokaOne    
            spawnAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)    
            spawnAllBtn.TextSize = 14    
            spawnAllBtn.Parent = toyContent    
            do    
                local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,8); c.Parent = spawnAllBtn    
                local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
                s.Color = Color3.fromRGB(200,150,255); s.Thickness = 1.8; s.Transparency = 0.1; s.Parent = spawnAllBtn    
                local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
                ts.Color = Color3.new(0,0,0); ts.Thickness = 1.5; ts.Parent = spawnAllBtn    
            end    
            spawnAllBtn.MouseEnter:Connect(function()    
                TweenService:Create(spawnAllBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(165,85,255)}):Play()    
            end)    
            spawnAllBtn.MouseLeave:Connect(function()    
                TweenService:Create(spawnAllBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(140,60,255)}):Play()    
            end)    
            spawnAllBtn.MouseButton1Click:Connect(function()    
                for _, toyName in ipairs(HIGH_TOYS) do    
                    local toyId = GetToyByName(toyName)    
                    if toyId then    
                        for _ = 1, 5 do createToy(toyId) end    
                    end    
                end    
                game.StarterGui:SetCore('SendNotification', { Title='High-Level Toys Spawned!', Text='5x of each toy added to inventory.', Duration=4 })    
            end)    
        end    
  
        local toy_name = toyNameBox.Text    
        local currentTime = os.clock()    
        local extendDuration = 1.5    
        local isExtension = currentTime < toyActiveAnimation.endTime    
        if isExtension then toyActiveAnimation.intensity = math.min(toyActiveAnimation.intensity + 0.3, 1.5)    
        else toyActiveAnimation.intensity = 1.0 end    
        if toyActiveAnimation.strokeTween then toyActiveAnimation.strokeTween:Cancel() end    
        if toyActiveAnimation.resetThread then coroutine.close(toyActiveAnimation.resetThread) end    
        local feedbackColor = Color3.fromRGB(255, 50, 50)    
        local spawnSuccess = false    
        if toy_name ~= '' then    
            local toyId = GetToyByName(toy_name)    
            if toyId then    
                createToy(toyId)    
                spawnSuccess = true    
                game.StarterGui:SetCore('SendNotification', { Title='Toy Spawned!', Text=toy_name..' has been spawned!', Duration=5 })    
            else    
                game.StarterGui:SetCore('SendNotification', { Title='Error', Text='Toy not found: '..toy_name, Duration=3 })    
            end    
        else    
            game.StarterGui:SetCore('SendNotification', { Title='Error', Text='Please enter a toy name!', Duration=3 })    
        end    
        toyActiveAnimation.lastSuccess = spawnSuccess    
        if isExtension and toyActiveAnimation.lastSuccess then    
            feedbackColor = Color3.fromRGB(0, 255 * toyActiveAnimation.intensity, 0)    
        end    
        toyButtonStroke.Color = feedbackColor    
        toyButtonStroke.Thickness = 2 * toyActiveAnimation.intensity    
        toyButtonStroke.Transparency = 0.1 / toyActiveAnimation.intensity    
        if isExtension then    
            toyActiveAnimation.strokeTween = TweenService:Create(toyButtonStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {    
                Thickness = 2.5 * toyActiveAnimation.intensity,    
                Transparency = 0.05 / toyActiveAnimation.intensity,    
            })    
            toyActiveAnimation.strokeTween:Play()    
        end    
        toyActiveAnimation.endTime = currentTime + extendDuration    
        toyActiveAnimation.resetThread = task.delay(extendDuration, function()    
            if os.clock() >= toyActiveAnimation.endTime then    
                TweenService:Create(toyButtonStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {    
                    Color = toyOriginalProperties.StrokeColor,    
                    Thickness = toyOriginalProperties.StrokeThickness,    
                    Transparency = toyOriginalProperties.StrokeTransparency,    
                }):Play()    
            end    
        end)    
    end)    
  
    -- ****════════════════════════════════════════****    
    -- EGGS TAB (FIXED)    
    -- ****════════════════════════════════════════****    
  
    local EGG_LIST = {    
        'Starter Egg','Cracked Egg','Pet Egg','Royal Egg','Retired Egg',    
        'Golden Egg','Diamond Egg','Aztec Egg','Basic Egg','Crystal Egg',    
        'Christmas Future Egg','Safari Egg','Jungle Egg','Farm Egg','Aussie Egg',    
        'Fossil Egg','Ocean Egg','Mythic Egg','Woodland Egg','Japan Egg',    
        'Southeast Asia Egg','Danger Egg','Urban Egg','Desert Egg','Garden Egg',    
        'Moon Egg','Blue Egg','Pink Egg','Christmas Egg (2019)','Easter 2020 Egg',    
        'Fool Egg','Zodiac Minion Egg','Wrapped Doll',    
    }    
  
    local EGG_PETS = {    
        ['farm egg'] = { legendary={'Owl','Crow'}, other={'Llama','Flaming Turkey','Cow','Swan','Silly Duck','Pig','Wild Boar','Chicken'} },    
        ['safari egg'] = { legendary={'Giraffe','Lion'}, other={'Cheetah','Elephant','Hyena','Gorilla','Puma','Rhino'} },    
        ['jungle egg'] = { legendary={'Parrot'}, other={'Toucan','Monkey','Jungle Boar','Jaguar','Turkey'} },    
        ['aussie egg'] = { legendary={'Platypus','Kookaburra'}, other={'Crocodile','Dingo','Emu','Kangaroo','Koala'} },    
        ['fossil egg'] = { legendary={'Dodo','T-Rex','Woolly Mammoth'}, other={'Ground Sloth','Glyptodon','Dilophosaurus','Stegosaurus','Triceratops'} },    
        ['ocean egg'] = { legendary={'Shark','Octopus'}, other={'Seahorse','Dolphin','Pufferfish','Narwhal','Squid','Clam'} },    
        ['woodland egg'] = { legendary={'Hedgehog'}, other={'Deer','Bunny','Rat','Robin','Fox','Squirrel'} },    
        ['mythic egg'] = { legendary={'Kirin','Merhorse','Wolpertinger'}, other={'Wyvern','Hydra','Salamander','Sasquatch','Cerberus'} },    
        ['christmas egg (2019)'] = { legendary={'Reindeer','Gingerbread Reindeer'}, other={'Santa Dog','Holiday Chick','Elf Shrew'} },    
        ['royal egg'] = { legendary={'Unicorn','Dragon'}, other={'Horse','Griffin'} },    
    }    
  
    local selectedEgg = nil    
  
    -- Patch hatch_effect to never anchor player    
    local SpecialEffectsApp = UIManager.apps.SpecialEffectsApp    
    local _origHatch = SpecialEffectsApp.hatch_effect    
    SpecialEffectsApp.hatch_effect = function(self, char)    
        if char and char:FindFirstChild('HumanoidRootPart') then    
            char.HumanoidRootPart.Anchored = false    
            local _c = char.HumanoidRootPart:GetPropertyChangedSignal('Anchored'):Connect(function()    
                if char.HumanoidRootPart.Anchored then char.HumanoidRootPart.Anchored = false end    
            end)    
            task.delay(6, function() _c:Disconnect() end)    
        end    
        return _origHatch(self, char)    
    end    
  
    -- ****──**** Egg dropdown toggle ****──****    
    local eggToggleBtn = Instance.new('TextButton')    
    eggToggleBtn.Size = UDim2.new(0.85, 0, 0, 26)    
    eggToggleBtn.Position = UDim2.new(0.075, 0, 0, 6)    
    eggToggleBtn.Text = 'Select Egg ▼'    
    eggToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)    
    eggToggleBtn.Font = Enum.Font.FredokaOne    
    eggToggleBtn.TextColor3 = Color3.fromRGB(255, 230, 100)    
    eggToggleBtn.TextSize = 14    
    eggToggleBtn.TextXAlignment = Enum.TextXAlignment.Left    
    eggToggleBtn.Parent = eggContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = eggToggleBtn    
        local s = Instance.new('UIStroke'); s.Color = Color3.fromRGB(255,230,100); s.Thickness = 1.5; s.Parent = eggToggleBtn    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = eggToggleBtn    
        local p = Instance.new('UIPadding'); p.PaddingLeft = UDim.new(0,8); p.Parent = eggToggleBtn    
    end    
  
    -- ****──**** Scrollable dropdown ****──****    
    local eggDropdown = Instance.new('Frame')    
    eggDropdown.Size = UDim2.new(0.85, 0, 0, 150)    
    eggDropdown.Position = UDim2.new(0.075, 0, 0, 36)    
    eggDropdown.BackgroundColor3 = Color3.fromRGB(28, 28, 42)    
    eggDropdown.BorderSizePixel = 0    
    eggDropdown.Visible = false    
    eggDropdown.ZIndex = 10    
    eggDropdown.ClipsDescendants = true    
    eggDropdown.Parent = eggContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = eggDropdown    
        local s = Instance.new('UIStroke'); s.Color = Color3.fromRGB(255,230,100); s.Thickness = 1.2; s.Parent = eggDropdown    
    end    
  
    local eggScroll = Instance.new('ScrollingFrame')    
    eggScroll.Size = UDim2.new(1,-6,1,-6)    
    eggScroll.Position = UDim2.new(0,3,0,3)    
    eggScroll.BackgroundTransparency = 1    
    eggScroll.BorderSizePixel = 0    
    eggScroll.ScrollBarThickness = 4    
    eggScroll.ScrollBarImageColor3 = Color3.fromRGB(255,230,100)    
    eggScroll.CanvasSize = UDim2.new(0,0,0,#EGG_LIST * 26)    
    eggScroll.ZIndex = 11    
    eggScroll.Parent = eggDropdown    
  
    local eggLayout = Instance.new('UIListLayout')    
    eggLayout.SortOrder = Enum.SortOrder.LayoutOrder    
    eggLayout.Padding = UDim.new(0,2)    
    eggLayout.Parent = eggScroll    
  
    local eggBtns = {}    
  
    for i, name in ipairs(EGG_LIST) do    
        local b = Instance.new('TextButton')    
        b.Size = UDim2.new(1,0,0,24)    
        b.BackgroundColor3 = Color3.fromRGB(45,45,65)    
        b.BackgroundTransparency = 0.2    
        b.Text = name    
        b.Font = Enum.Font.FredokaOne    
        b.TextSize = 13    
        b.TextColor3 = Color3.fromRGB(210,210,240)    
        b.TextXAlignment = Enum.TextXAlignment.Left    
        b.ZIndex = 12    
        b.LayoutOrder = i    
        b.Parent = eggScroll    
        local bc = Instance.new('UICorner'); bc.CornerRadius = UDim.new(0,4); bc.Parent = b    
        local bp = Instance.new('UIPadding'); bp.PaddingLeft = UDim.new(0,8); bp.Parent = b    
        eggBtns[name] = b    
  
        b.MouseEnter:Connect(function()    
            if selectedEgg ~= name:lower() then b.BackgroundColor3 = Color3.fromRGB(60,55,90) end    
        end)    
        b.MouseLeave:Connect(function()    
            if selectedEgg ~= name:lower() then b.BackgroundColor3 = Color3.fromRGB(45,45,65) end    
        end)    
  
        b.MouseButton1Click:Connect(function()    
            for _, ob in pairs(eggBtns) do    
                ob.BackgroundColor3 = Color3.fromRGB(45,45,65)    
                ob.TextColor3 = Color3.fromRGB(210,210,240)    
            end    
            selectedEgg = name:lower()    
            b.BackgroundColor3 = Color3.fromRGB(75,55,115)    
            b.TextColor3 = Color3.fromRGB(255,230,100)    
            eggToggleBtn.Text = name .. ' ▼'    
            eggDropdown.Visible = false    
        end)    
    end    
  
    eggToggleBtn.MouseButton1Click:Connect(function()    
        eggDropdown.Visible = not eggDropdown.Visible    
        local sel = selectedEgg    
        local label = 'Select Egg'    
        if sel then    
            for n,_ in pairs(eggBtns) do    
                if n:lower() == sel then label = n; break end    
            end    
        end    
        eggToggleBtn.Text = label .. (eggDropdown.Visible and ' ▲' or ' ▼')    
    end)    
  
    -- ****──**** Spawn Egg button ****──****    
    local spawnEggBtn = Instance.new('TextButton')    
    spawnEggBtn.Size = UDim2.new(0.85, 0, 0, 26)    
    spawnEggBtn.Position = UDim2.new(0.075, 0, 0, 36)    
    spawnEggBtn.Text = 'Spawn Egg'    
    spawnEggBtn.BackgroundColor3 = Color3.fromRGB(0,120,190)    
    spawnEggBtn.BackgroundTransparency = 0.1    
    spawnEggBtn.Font = Enum.Font.FredokaOne    
    spawnEggBtn.TextColor3 = Color3.fromRGB(255,255,255)    
    spawnEggBtn.TextSize = 15    
    spawnEggBtn.Parent = eggContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,8); c.Parent = spawnEggBtn    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(255,255,255); s.Thickness = 1.5; s.Transparency = 0.2; s.Parent = spawnEggBtn    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.5; ts.Parent = spawnEggBtn    
    end    
  
    spawnEggBtn.MouseEnter:Connect(function()    
        TweenService:Create(spawnEggBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(0,150,220)}):Play()    
    end)    
    spawnEggBtn.MouseLeave:Connect(function()    
        TweenService:Create(spawnEggBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(0,120,190)}):Play()    
    end)    
  
    -- Hide spawnEggBtn when dropdown is open, show when closed    
    eggDropdown:GetPropertyChangedSignal('Visible'):Connect(function()    
        spawnEggBtn.Visible = not eggDropdown.Visible    
    end)    
  
    spawnEggBtn.MouseButton1Click:Connect(function()    
        if not selectedEgg then    
            game.StarterGui:SetCore('SendNotification', {Title='No Egg Selected', Text='Pick an egg first!', Duration=3})    
            return    
        end    
  
        -- Find the egg toy ID from KindDB/InventoryDB by matching name    
        local toyId = nil    
  
        -- Try KindDB (items) first    
        for id, item in pairs(items) do    
            if item.name and item.name:lower() == selectedEgg then    
                toyId = id    
                break    
            end    
        end    
  
        -- Fallback: try InventoryDB toys    
        if not toyId then    
            toyId = GetToyByName(selectedEgg)    
            -- GetToyByName already returns the id string, so re-map if needed    
        end    
  
        if toyId then    
            -- Use createToy (same as the rest of the script) to add the egg    
            local newToy = createToy(toyId)    
            if newToy then    
                task.wait(0.05)    
                -- Equip it to the player's hand so it shows as held    
                pcall(function()    
                    router.get('ToolAPI/Equip'):InvokeServer(newToy.unique)    
                end)    
                game.StarterGui:SetCore('SendNotification', {    
                    Title = '🥚 Egg Spawned!',    
                    Text = selectedEgg:gsub("^%l", string.upper) .. ' added & equipped.',    
                    Duration = 3,    
                })    
            end    
        else    
            game.StarterGui:SetCore('SendNotification', {    
                Title = 'Not Found',    
                Text = 'Egg not found: ' .. selectedEgg,    
                Duration = 4,    
            })    
        end    
    end)    
  
    -- ****──**** Hatch Egg button ****──****    
    local hatchEggBtn = Instance.new('TextButton')    
    hatchEggBtn.Size = UDim2.new(0.85, 0, 0, 26)    
    hatchEggBtn.Position = UDim2.new(0.075, 0, 0, 66)    
    hatchEggBtn.Text = 'Hatch Egg!'    
    hatchEggBtn.BackgroundColor3 = Color3.fromRGB(255,155,0)    
    hatchEggBtn.BackgroundTransparency = 0.1    
    hatchEggBtn.Font = Enum.Font.FredokaOne    
    hatchEggBtn.TextColor3 = Color3.fromRGB(255,255,255)    
    hatchEggBtn.TextSize = 15    
    hatchEggBtn.Parent = eggContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,8); c.Parent = hatchEggBtn    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(255,230,100); s.Thickness = 1.5; s.Transparency = 0.1; s.Parent = hatchEggBtn    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.5; ts.Parent = hatchEggBtn    
    end    
  
    hatchEggBtn.MouseEnter:Connect(function()    
        TweenService:Create(hatchEggBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(255,190,40)}):Play()    
    end)    
    hatchEggBtn.MouseLeave:Connect(function()    
        TweenService:Create(hatchEggBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(255,155,0)}):Play()    
    end)    
  
    -- ****──**** "Delete All Eggs" button ****──****    
    local deleteAllEggsBtn = Instance.new('TextButton')    
    deleteAllEggsBtn.Size = UDim2.new(0.85, 0, 0, 26)    
    deleteAllEggsBtn.Position = UDim2.new(0.075, 0, 0, 96)    
    deleteAllEggsBtn.Text = '🗑 Delete All Eggs'    
    deleteAllEggsBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)    
    deleteAllEggsBtn.BackgroundTransparency = 0.1    
    deleteAllEggsBtn.Font = Enum.Font.FredokaOne    
    deleteAllEggsBtn.TextColor3 = Color3.fromRGB(255, 200, 200)    
    deleteAllEggsBtn.TextSize = 14    
    deleteAllEggsBtn.Parent = eggContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,8); c.Parent = deleteAllEggsBtn    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(255,100,100); s.Thickness = 1.5; s.Transparency = 0.2; s.Parent = deleteAllEggsBtn    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.5; ts.Parent = deleteAllEggsBtn    
    end    
  
    deleteAllEggsBtn.MouseEnter:Connect(function()    
        TweenService:Create(deleteAllEggsBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(210,50,50)}):Play()    
    end)    
    deleteAllEggsBtn.MouseLeave:Connect(function()    
        TweenService:Create(deleteAllEggsBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(180,30,30)}):Play()    
    end)    
  
    deleteAllEggsBtn.MouseButton1Click:Connect(function()    
        local EGG_KEYWORDS = {'egg', 'wrapped doll'}    
        local removed = 0    
        set_thread_identity(2)    
        updateData('inventory', function(inv)    
            if inv.toys then    
                local toRemove = {}    
                for uid, toy in pairs(inv.toys) do    
                    local n = (items[toy.id] and items[toy.id].name or ''):lower()    
                    for _, kw in ipairs(EGG_KEYWORDS) do    
                        if n:find(kw) then    
                            table.insert(toRemove, uid)    
                            break    
                        end    
                    end    
                end    
                for _, uid in ipairs(toRemove) do    
                    inv.toys[uid] = nil    
                    removed = removed + 1    
                end    
            end    
            return inv    
        end)    
        set_thread_identity(8)    
        if removed > 0 then    
            game.StarterGui:SetCore('SendNotification', {    
                Title = '🗑 Eggs Deleted',    
                Text = removed .. ' egg(s) removed from inventory.',    
                Duration = 4,    
            })    
        else    
            game.StarterGui:SetCore('SendNotification', {    
                Title = 'No Eggs Found',    
                Text = 'No eggs in inventory to delete.',    
                Duration = 3,    
            })    
        end    
    end)    
  
    -- ****──**** "Configurations" label ****──****    
    local configLabel = Instance.new('TextLabel')    
    configLabel.Size = UDim2.new(0.85, 0, 0, 20)    
    configLabel.Position = UDim2.new(0.075, 0, 0, 128)    
    configLabel.BackgroundTransparency = 1    
    configLabel.Text = '— Configurations —'    
    configLabel.Font = Enum.Font.FredokaOne    
    configLabel.TextSize = 13    
    configLabel.TextColor3 = Color3.fromRGB(180, 180, 220)    
    configLabel.TextXAlignment = Enum.TextXAlignment.Center    
    configLabel.Parent = eggContent    
  
    -- ****──**** Pet name override textbox (moved below Configurations label) ****──****    
    local eggPetNameBox = Instance.new('TextBox')    
    eggPetNameBox.Size = UDim2.new(0.85, 0, 0, 26)    
    eggPetNameBox.Position = UDim2.new(0.075, 0, 0, 152)    
    eggPetNameBox.BackgroundColor3 = Color3.fromRGB(40,40,50)    
    eggPetNameBox.BackgroundTransparency = 0.2    
    eggPetNameBox.TextColor3 = Color3.fromRGB(255,255,255)    
    eggPetNameBox.TextSize = 14    
    eggPetNameBox.Font = Enum.Font.FredokaOne    
    eggPetNameBox.PlaceholderText = 'Pet to hatch (optional override)'    
    eggPetNameBox.Text = ''    
    eggPetNameBox.ClearTextOnFocus = false    
    eggPetNameBox.ZIndex = 5    
    eggPetNameBox.Parent = eggContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = eggPetNameBox    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(255,255,255); s.Thickness = 1.8; s.Transparency = 0.3; s.Parent = eggPetNameBox    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = eggPetNameBox    
    end    
  
    -- Auto-capitalise pet name in hatch box    
    eggPetNameBox:GetPropertyChangedSignal('Text'):Connect(function()    
        local cursor = eggPetNameBox.CursorPosition    
        local inputText = eggPetNameBox.Text    
        local newText = capitalizeWords(inputText)    
        if newText ~= inputText then    
            eggPetNameBox.Text = newText    
            eggPetNameBox.CursorPosition = math.max(1, math.min(cursor + (#newText - #inputText), #newText + 1))    
        end    
    end)    
  
    -- Hide name box when dropdown is open    
    eggDropdown:GetPropertyChangedSignal('Visible'):Connect(function()    
        eggPetNameBox.Visible = not eggDropdown.Visible    
        configLabel.Visible = not eggDropdown.Visible    
        deleteAllEggsBtn.Visible = not eggDropdown.Visible    
    end)    
  
    -- ****──**** Hatch Egg logic ****──****    
    hatchEggBtn.MouseButton1Click:Connect(function()    
        local IDB = require(game.ReplicatedStorage.Fsys).load('InventoryDB')    
        local eggName = selectedEgg    
        if not eggName then    
            local ch = LocalPlayer.Character    
            if ch then    
                local t = ch:FindFirstChildOfClass('Tool')    
                if t then eggName = t.Name:lower() end    
            end    
        end    
        if not eggName then    
            local inv = clientData.get('inventory')    
            if inv and inv.toys then    
                for _, toy in pairs(inv.toys) do    
                    local item = items[toy.id]    
                    if item and item.name and item.name:lower():find('egg') then    
                        eggName = item.name:lower(); break    
                    end    
                end    
            end    
        end    
        if not eggName then eggName = '' end    
  
        -- Play hatch particles    
        local targetPart = nil    
        local wrappers = clientData.get('pet_char_wrappers')    
        if wrappers and #wrappers > 0 then    
            local petModel = wrappers[#wrappers].char    
            if petModel and petModel:IsDescendantOf(workspace) then    
                targetPart = petModel:FindFirstChild('HumanoidRootPart') or petModel:FindFirstChildOfClass('BasePart')    
            end    
        end    
        if not targetPart then    
            local ch = LocalPlayer.Character    
            if ch then    
                local t = ch:FindFirstChildOfClass('Tool')    
                targetPart = t and t:FindFirstChild('Handle')    
            end    
        end    
        if not targetPart then    
            local ch = LocalPlayer.Character    
            if ch then targetPart = ch:FindFirstChild('HumanoidRootPart') end    
        end    
  
        local ANIM_DURATION = 2.5    
        local ok, hatchParticles = pcall(function()    
            return game.ReplicatedStorage:WaitForChild('Resources',3):WaitForChild('Particles',3):WaitForChild('Hatch',3)    
        end)    
        if ok and hatchParticles and targetPart then    
            local att = Instance.new('Attachment')    
            att.Parent = targetPart    
            for _, p in ipairs(hatchParticles:GetChildren()) do p:Clone().Parent = att end    
            for _, p in ipairs(att:GetChildren()) do p.Enabled = true end    
            task.delay(ANIM_DURATION, function()    
                for _, p in ipairs(att:GetChildren()) do p.Enabled = false end    
                game:GetService('Debris'):AddItem(att, 5)    
            end)    
        end    
  
        task.spawn(function()    
            local overrideName = eggPetNameBox.Text ~= '' and eggPetNameBox.Text or nil    
            local chosenId = nil    
  
            if overrideName then    
                -- Use the exact same GetPetByName helper as the rest of the script    
                chosenId = GetPetByName(overrideName)    
                if not chosenId then    
                    game.StarterGui:SetCore('SendNotification', {Title='Pet Not Found', Text=overrideName..' not found.', Duration=3})    
                    return    
                end    
            else    
                local eggData = EGG_PETS[eggName]    
  
                local function namesToIds(names)    
                    local ids = {}    
                    for _, name in ipairs(names) do    
                        for petId, pe in pairs(IDB.pets or {}) do    
                            if pe.name and pe.name:lower() == name:lower() then    
                                table.insert(ids, petId); break    
                            end    
                        end    
                    end    
                    return ids    
                end    
  
                local legPool = eggData and namesToIds(eggData.legendary) or {}    
                local othPool = eggData and namesToIds(eggData.other) or {}    
  
                if #legPool == 0 and #othPool == 0 then    
                    for petId, pe in pairs(IDB.pets or {}) do    
                        if not pe.is_egg then    
                            if (pe.rarity or ''):lower():find('legend') then    
                                table.insert(legPool, petId)    
                            else    
                                table.insert(othPool, petId)    
                            end    
                        end    
                    end    
                end    
  
                local weightedPool = {}    
                for _, id in ipairs(legPool) do    
                    for _ = 1, 3 do table.insert(weightedPool, id) end    
                end    
                for _, id in ipairs(othPool) do    
                    table.insert(weightedPool, id)    
                end    
  
                if #weightedPool > 0 then    
                    chosenId = weightedPool[math.random(#weightedPool)]    
                end    
            end    
  
            if not chosenId then return end    
  
            task.wait(ANIM_DURATION)    
  
            -- Destroy egg tool from character hand    
            local char = LocalPlayer.Character    
            if char then    
                local tool = char:FindFirstChildOfClass('Tool')    
                if tool then    
                    pcall(function()    
                        router.get('ToolAPI/Unequip'):InvokeServer(tool:GetAttribute('unique_id') or tool.Name)    
                    end)    
                    task.wait(0.1)    
                    pcall(function() tool:Destroy() end)    
                end    
            end    
  
            -- Remove egg from inventory (same updateData/predict pattern as createPet)    
            set_thread_identity(2)    
            updateData('inventory', function(inv)    
                local toRemove = nil    
                if inv.toys then    
                    for uid, toy in pairs(inv.toys) do    
                        local n = (items[toy.id] and items[toy.id].name or ''):lower()    
                        if n == eggName then toRemove = uid; break end    
                    end    
                    if not toRemove then    
                        for uid, toy in pairs(inv.toys) do    
                            local n = (items[toy.id] and items[toy.id].name or ''):lower()    
                            if n:find('egg') or n == 'wrapped doll' then toRemove = uid; break end    
                        end    
                    end    
                    if toRemove then inv.toys[toRemove] = nil end    
                end    
                return inv    
            end)    
            set_thread_identity(8)    
  
            -- Spawn hatched pet using createPet (same as Pets tab, respects all active flags + selectedAge)    
            local newPet = createPet(chosenId, {    
                pet_trick_level = math.random(0, 5),    
                neon = activeFlags['N'],    
                mega_neon = activeFlags['M'],    
                rideable = activeFlags['R'],    
                flyable = activeFlags['F'],    
                age = selectedAge or 1,    
                ailments_completed = 0,    
                rp_name = '',    
            })    
  
            -- Equip the pet so it follows the player (using the hooked router)    
            if newPet then    
                task.wait(0.2)    
                pcall(function() router.get('ToolAPI/Equip'):InvokeServer(newPet.unique) end)    
            end    
  
            local petName = IDB.pets[chosenId] and IDB.pets[chosenId].name or 'a pet'    
            game.StarterGui:SetCore('SendNotification', {    
                Title = '🐣 Hatched!',    
                Text = 'You got: ' .. petName .. '!',    
                Duration = 5,    
            })    
        end)    
    end)    
  
    -- ****────────────────────────────────────────****    
    -- PET WEAR SECTION    
    -- ****────────────────────────────────────────****    
  
    local function GetPetWearByName(name)    
        for id, v in pairs(InventoryDB.pet_accessories or {}) do    
            if v.name and v.name:lower() == name:lower() then return id end    
        end    
        return false    
    end    
  
    local function equipWearOnPet(wearId)    
        local IDB2 = require(game.ReplicatedStorage.Fsys).load('InventoryDB')    
        local PetAccessoryEquipHelper = require(game.ReplicatedStorage.Fsys).load('PetAccessoryEquipHelper')    
        local dl = require(game.ReplicatedStorage.Fsys).load('DownloadClient')    
  
        local wearEntry = IDB2.pet_accessories and IDB2.pet_accessories[wearId]    
        if not wearEntry then    
            warn('[PetWear] No entry in InventoryDB.pet_accessories for: ' .. tostring(wearId))    
            game.StarterGui:SetCore('SendNotification', {Title='Not Found', Text='Wear entry missing from DB.', Duration=4})    
            return false    
        end    
  
        local wrappers = clientData.get('pet_char_wrappers')    
        if not wrappers or #wrappers == 0 then    
            game.StarterGui:SetCore('SendNotification', {Title='No Pet Equipped', Text='Equip a pet first!', Duration=4})    
            return false    
        end    
  
        local petModel = wrappers[#wrappers].char    
        if not petModel or not petModel:IsDescendantOf(workspace) then    
            game.StarterGui:SetCore('SendNotification', {Title='Pet Not Found', Text='Could not find pet model in workspace.', Duration=4})    
            return false    
        end    
  
        task.spawn(function()    
            local ok, accessoryAsset = pcall(function()    
                return dl.promise_download_copy('PetAvatarResources', wearEntry.model_handle):expect()    
            end)    
            if not ok or not accessoryAsset then    
                warn('[PetWear] Failed to download asset for: ' .. tostring(wearEntry.model_handle))    
                game.StarterGui:SetCore('SendNotification', {Title='Download Failed', Text='Could not load accessory model.', Duration=4})    
                return    
            end    
  
            local success, result = pcall(function()    
                return PetAccessoryEquipHelper.equip_accessory({    
                    pet_model = petModel,    
                    accessory_base_asset = accessoryAsset,    
                    accessory_item_entry = wearEntry,    
                    play_poof_effect = true,    
                    is_mannequin = false,    
                })    
            end)    
  
            if success and result then    
                game.StarterGui:SetCore('SendNotification', {Title='🪽 Equipped!', Text=(wearEntry.name or wearId)..' equipped on your pet.', Duration=4})    
            else    
                warn('[PetWear] equip_accessory failed: ' .. tostring(result))    
                game.StarterGui:SetCore('SendNotification', {Title='Equip Failed', Text='Check console for error.', Duration=4})    
            end    
        end)    
        return true    
    end    
  
    local petWearNameBox = Instance.new('TextBox')    
    petWearNameBox.Size = UDim2.new(0.85, 0, 0, 26)    
    petWearNameBox.Position = UDim2.new(0.075, 0, 0, 198)    
    petWearNameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)    
    petWearNameBox.BackgroundTransparency = 0.2    
    petWearNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)    
    petWearNameBox.TextSize = 13    
    petWearNameBox.Font = Enum.Font.FredokaOne    
    petWearNameBox.PlaceholderText = 'Enter Pet Wear Name'    
    petWearNameBox.Text = ''    
    petWearNameBox.ClearTextOnFocus = false    
    petWearNameBox.Parent = petContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = petWearNameBox    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(220,180,255); s.Thickness = 1.8; s.Transparency = 0.25; s.Parent = petWearNameBox    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = petWearNameBox    
    end    
  
    petWearNameBox:GetPropertyChangedSignal('Text'):Connect(function()    
        local cursor = petWearNameBox.CursorPosition    
        local inputText = petWearNameBox.Text    
        local newText = capitalizeWords(inputText)    
        if newText ~= inputText then    
            petWearNameBox.Text = newText    
            petWearNameBox.CursorPosition = math.max(1, math.min(cursor + (#newText - #inputText), #newText + 1))    
        end    
    end)    
  
    local addPetWearBtn = Instance.new('TextButton')    
    addPetWearBtn.Size = UDim2.new(0.85, 0, 0, 26)    
    addPetWearBtn.Position = UDim2.new(0.075, 0, 0, 228)    
    addPetWearBtn.Text = '✦ Add PetWear'    
    addPetWearBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 255)    
    addPetWearBtn.BackgroundTransparency = 0.1    
    addPetWearBtn.Font = Enum.Font.FredokaOne    
    addPetWearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)    
    addPetWearBtn.TextSize = 13    
    addPetWearBtn.Parent = petContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,8); c.Parent = addPetWearBtn    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(220,180,255); s.Thickness = 1.8; s.Transparency = 0.1; s.Parent = addPetWearBtn    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = addPetWearBtn    
    end    
  
    addPetWearBtn.MouseEnter:Connect(function()    
        TweenService:Create(addPetWearBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(200,130,255)}):Play()    
    end)    
    addPetWearBtn.MouseLeave:Connect(function()    
        TweenService:Create(addPetWearBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(180,100,255)}):Play()    
    end)    
  
    addPetWearBtn.MouseButton1Click:Connect(function()    
        local wearName = petWearNameBox.Text    
        if wearName == '' then    
            game.StarterGui:SetCore('SendNotification', {Title='Error', Text='Enter a pet wear name!', Duration=3})    
            return    
        end    
        local wearId = GetPetWearByName(wearName)    
        if wearId then    
            equipWearOnPet(wearId)    
        else    
            warn('[PetWear] "' .. wearName .. '" not found.')    
            game.StarterGui:SetCore('SendNotification', {Title='Not Found', Text='"'..wearName..'" not found — check console.', Duration=5})    
        end    
    end)    
  
    local PREPPY_WEARS = { 'Unicorn Horn', '', 'Pink Cat Ear Headphones', 'Rainbow Maker', '2022 Birthday Cupcake Shoes' }    
  
    local preppyPWBtn = Instance.new('TextButton')    
    preppyPWBtn.Size = UDim2.new(0.85, 0, 0, 26)    
    preppyPWBtn.Position = UDim2.new(0.075, 0, 0, 258)    
    preppyPWBtn.Text = '🎀 Add Preppy PW'    
    preppyPWBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 180)    
    preppyPWBtn.BackgroundTransparency = 0.1    
    preppyPWBtn.Font = Enum.Font.FredokaOne    
    preppyPWBtn.TextColor3 = Color3.fromRGB(255, 255, 255)    
    preppyPWBtn.TextSize = 13    
    preppyPWBtn.Parent = petContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,8); c.Parent = preppyPWBtn    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(255,180,220); s.Thickness = 1.8; s.Transparency = 0.1; s.Parent = preppyPWBtn    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = preppyPWBtn    
    end    
  
    preppyPWBtn.MouseEnter:Connect(function()    
        TweenService:Create(preppyPWBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(255,130,200)}):Play()    
    end)    
    preppyPWBtn.MouseLeave:Connect(function()    
        TweenService:Create(preppyPWBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(255,100,180)}):Play()    
    end)    
  
    preppyPWBtn.MouseButton1Click:Connect(function()    
        local added, missed = {}, {}    
        for _, wearName in ipairs(PREPPY_WEARS) do    
            local wearId = GetPetWearByName(wearName)    
            if wearId then equipWearOnPet(wearId); table.insert(added, wearName)    
            else warn('[PetWear] Not found: '..wearName); table.insert(missed, wearName) end    
        end    
        if #added > 0 then    
            game.StarterGui:SetCore('SendNotification', {    
                Title = '🎀 Preppy PW Equipped!',    
                Text = #added..' wears equipped'..(#missed > 0 and ' ('..#missed..' not found)' or '')..'.',    
                Duration = 5,    
            })    
        else    
            game.StarterGui:SetCore('SendNotification', {Title='None Found', Text='No preppy wears found.', Duration=4})    
        end    
    end)    
  
    -- ****────────────────────────────────────────****    
    -- PET BODY COLOUR SECTION    
    -- ****────────────────────────────────────────****    
  
    local petColourBox = Instance.new('TextBox')    
    petColourBox.Size = UDim2.new(0.85, 0, 0, 26)    
    petColourBox.Position = UDim2.new(0.075, 0, 0, 288)    
    petColourBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)    
    petColourBox.BackgroundTransparency = 0.2    
    petColourBox.TextColor3 = Color3.fromRGB(255, 255, 255)    
    petColourBox.TextSize = 13    
    petColourBox.Font = Enum.Font.FredokaOne    
    petColourBox.PlaceholderText = 'Hex colour e.g. FF90C8'    
    petColourBox.Text = ''    
    petColourBox.ClearTextOnFocus = false    
    petColourBox.Parent = petContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = petColourBox    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(255, 180, 220); s.Thickness = 1.8; s.Transparency = 0.25; s.Parent = petColourBox    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = petColourBox    
    end    
  
    local function hexToColor3(hex)    
        hex = hex:gsub('^#', ''):gsub('%s+', '')    
        if #hex ~= 6 then return nil end    
        local r = tonumber(hex:sub(1,2), 16)    
        local g = tonumber(hex:sub(3,4), 16)    
        local b = tonumber(hex:sub(5,6), 16)    
        if not r or not g or not b then return nil end    
        return Color3.fromRGB(r, g, b)    
    end    
  
    local colourBoxGlow = petColourBox:FindFirstChildWhichIsA('UIStroke')    
  
    petColourBox:GetPropertyChangedSignal('Text'):Connect(function()    
        local col = hexToColor3(petColourBox.Text)    
        local targetColor = col and Color3.fromRGB(120, 255, 150) or (petColourBox.Text == '' and Color3.fromRGB(255, 180, 220) or Color3.fromRGB(255, 100, 100))    
        TweenService:Create(colourBoxGlow, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Color=targetColor}):Play()    
    end)    
  
    -- Stores original colours of parts that look like eyes (very dark or very light,    
    -- small size) so we can restore them after colouring the body.    
    -- Strategy: colour everything that isn't Neon, then restore any part whose    
    -- ORIGINAL colour was very dark (pupil) or very desaturated-bright (white sclera),    
    -- AND whose part name contains a known eye keyword OR whose size is tiny.    
    -- Additionally we track by name as a first-pass fast skip.    
    local savedEyeColours = {} -- [part] = originalColor3    
  
    local function snapshotEyes(searchRoot)    
        savedEyeColours = {}    
        local eyeKeywords = { 'eye', 'pupil', 'iris', 'cornea', 'sclera', 'eyelid', 'eyelash', 'eyebrow', 'retina', 'lens', 'highlight', 'gloss', 'shine', 'spec' }    
        for _, part in ipairs(searchRoot:GetDescendants()) do    
            if part:IsA('BasePart') then    
                local name = part.Name:lower()    
                local isNamedEye = false    
                for _, kw in ipairs(eyeKeywords) do    
                    if name:find(kw) then isNamedEye = true; break end    
                end    
                -- Also treat very small parts as likely eye details    
                local size = part.Size    
                local isSmall = (size.X < 0.15 and size.Y < 0.15 and size.Z < 0.15)    
                -- Treat very dark or very white/grey parts as eye details    
                local c = part.Color    
                local brightness = (c.R + c.G + c.B) / 3    
                local isVeryDark = brightness < 0.12    
                local isVeryLight = brightness > 0.88    
                local isSaturated = math.abs(c.R - c.G) > 0.15 or math.abs(c.G - c.B) > 0.15 or math.abs(c.R - c.B) > 0.15    
  
                -- Eye heuristic: named eye part, OR (small AND (very dark or very light but not strongly saturated body colour))    
                if isNamedEye or (isSmall and (isVeryDark or (isVeryLight and not isSaturated))) then    
                    savedEyeColours[part] = part.Color    
                end    
            end    
        end    
    end    
  
    local function applyColourToPet(targetColor)    
        local wrappers = clientData.get('pet_char_wrappers')    
        if not wrappers or #wrappers == 0 then    
            game.StarterGui:SetCore('SendNotification', {Title='No Pet Equipped', Text='Equip a pet first!', Duration=3})    
            return false    
        end    
  
        local petModel = wrappers[#wrappers].char    
        if not petModel or not petModel:IsDescendantOf(workspace) then    
            game.StarterGui:SetCore('SendNotification', {Title='Pet Not Found', Text='Could not find pet model.', Duration=3})    
            return false    
        end    
  
        local searchRoot = petModel:FindFirstChild('PetModel') or petModel    
  
        -- Snapshot which parts look like eyes BEFORE we change anything    
        snapshotEyes(searchRoot)    
  
        local coloured = 0    
        for _, part in ipairs(searchRoot:GetDescendants()) do    
            if part:IsA('BasePart') and part.Material ~= Enum.Material.Neon then    
                if not savedEyeColours[part] then    
                    part.Color = targetColor    
                    coloured = coloured + 1    
                end    
            end    
        end    
  
        -- Restore eye parts to their original colours    
        for part, origColor in pairs(savedEyeColours) do    
            if part and part.Parent then    
                part.Color = origColor    
            end    
        end    
  
        return coloured    
    end    
  
    local changeColourBtn = Instance.new('TextButton')    
    changeColourBtn.Size = UDim2.new(0.85, 0, 0, 26)    
    changeColourBtn.Position = UDim2.new(0.075, 0, 0, 318)    
    changeColourBtn.Text = '🖌 Change Colour'    
    changeColourBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 200)    
    changeColourBtn.BackgroundTransparency = 0.1    
    changeColourBtn.Font = Enum.Font.FredokaOne    
    changeColourBtn.TextColor3 = Color3.fromRGB(255, 255, 255)    
    changeColourBtn.TextSize = 13    
    changeColourBtn.Parent = petContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,8); c.Parent = changeColourBtn    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(220, 160, 255); s.Thickness = 1.8; s.Transparency = 0.1; s.Parent = changeColourBtn    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = changeColourBtn    
    end    
  
    changeColourBtn.MouseEnter:Connect(function()    
        TweenService:Create(changeColourBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(185,105,225)}):Play()    
    end)    
    changeColourBtn.MouseLeave:Connect(function()    
        TweenService:Create(changeColourBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(160,80,200)}):Play()    
    end)    
  
    changeColourBtn.MouseButton1Click:Connect(function()    
        local col = hexToColor3(petColourBox.Text)    
        if not col then    
            game.StarterGui:SetCore('SendNotification', {Title='Invalid Hex', Text='Enter a valid 6-digit hex e.g. FF90C8', Duration=3})    
            return    
        end    
        local coloured = applyColourToPet(col)    
        if coloured and coloured > 0 then    
            game.StarterGui:SetCore('SendNotification', {    
                Title = '🖌 Colour Applied!',    
                Text = '#'..petColourBox.Text:gsub('^#',''):upper()..' applied to '..coloured..' parts.',    
                Duration = 4,    
            })    
        end    
    end)    
  
    local colourPreppyBtn = Instance.new('TextButton')    
    colourPreppyBtn.Size = UDim2.new(0.85, 0, 0, 26)    
    colourPreppyBtn.Position = UDim2.new(0.075, 0, 0, 348)    
    colourPreppyBtn.Text = '🎀 Colour Preppy Pet'    
    colourPreppyBtn.BackgroundColor3 = Color3.fromRGB(255, 155, 205)    
    colourPreppyBtn.BackgroundTransparency = 0.1    
    colourPreppyBtn.Font = Enum.Font.FredokaOne    
    colourPreppyBtn.TextColor3 = Color3.fromRGB(80, 20, 50)    
    colourPreppyBtn.TextSize = 13    
    colourPreppyBtn.Parent = petContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,8); c.Parent = colourPreppyBtn    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(255, 210, 235); s.Thickness = 1.8; s.Transparency = 0.1; s.Parent = colourPreppyBtn    
        local ts = Instance.new('UIStroke'); ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual    
        ts.Color = Color3.new(0,0,0); ts.Thickness = 1.2; ts.Parent = colourPreppyBtn    
    end    
  
    colourPreppyBtn.MouseEnter:Connect(function()    
        TweenService:Create(colourPreppyBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(255, 175, 215)}):Play()    
    end)    
    colourPreppyBtn.MouseLeave:Connect(function()    
        TweenService:Create(colourPreppyBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(255, 155, 205)}):Play()    
    end)    
  
    colourPreppyBtn.MouseButton1Click:Connect(function()    
        local coloured = applyColourToPet(Color3.fromRGB(255, 144, 200))    
        if coloured and coloured > 0 then    
            game.StarterGui:SetCore('SendNotification', {    
                Title = '🎀 Preppy Coloured!',    
                Text = 'Pet body coloured to #FF90C8 ('..coloured..' parts).',    
                Duration = 4,    
            })    
        end    
    end)    
  
    -- ****────────────────────────────────────────****    
    -- TRICKS TAB    
    -- ****────────────────────────────────────────****    
  
    local PetEntityManager = require(game.ReplicatedStorage.Fsys).load('PetEntityManager')    
    local AnimationManager2 = require(game.ReplicatedStorage.Fsys).load('AnimationManager')    
    local RouterClient = require(game.ReplicatedStorage.Fsys).load('RouterClient')    
  
    local function doTrick(animName)    
        local entities = PetEntityManager.get_local_owned_pet_entities()    
        if not entities or #entities == 0 then    
            game.StarterGui:SetCore('SendNotification', {Title='No Pet', Text='Equip a pet first!', Duration=3})    
            return false    
        end    
        local entity = entities[#entities]    
        local petModel = entity.base.pet_model    
        if not petModel then return false end    
  
        if not AnimationManager2.animations[animName] then    
            warn('[Tricks] Animation not found: ' .. tostring(animName))    
            return false    
        end    
  
        local animator = (entity.shared_cache and entity.shared_cache.Animator) or petModel:FindFirstChildWhichIsA('Animator', true)    
  
        if not animator then    
            local ac = petModel:FindFirstChildOfClass('AnimationController')    
            if not ac then    
                ac = Instance.new('AnimationController')    
                ac.Parent = petModel    
            end    
            animator = ac:FindFirstChildOfClass('Animator')    
            if not animator then    
                animator = Instance.new('Animator')    
                animator.Parent = ac    
            end    
        end    
  
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do    
            local n = track.Name:lower()    
            if n:find('trick') or n:find('rollover') or n:find('dance') or n:find('backflip') then    
                track:Stop(0.1)    
            end    
        end    
  
        local track = animator:LoadAnimation(AnimationManager2.get_track(animName))    
        track:Play()    
        return true    
    end    
  
    local function unlockAllTricksOnInterface()    
        local entities = PetEntityManager.get_local_owned_pet_entities()    
        if not entities or #entities == 0 then return end    
        local entity = entities[#entities]    
        if entity.base.char_wrapper and entity.base.char_wrapper.pet_progression then    
            entity.base.char_wrapper.pet_progression.age = 6    
        end    
        local uid = entity.base.char_wrapper and entity.base.char_wrapper.pet_unique    
        if uid then    
            pcall(function()    
                RouterClient.get('PetAPI/UpdatePetTrickLevel'):FireServer(uid)    
            end)    
        end    
    end    
  
    -- Tricks tab button    
    trickTab = Instance.new('TextButton')    
    trickTab.Size = UDim2.new(0.25, 0, 1, 0)    
    trickTab.Position = UDim2.new(0.75, 0, 0, 0)    
    trickTab.Text = 'Tricks'    
    trickTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)    
    trickTab.BackgroundTransparency = 0.1    
    trickTab.Font = Enum.Font.FredokaOne    
    trickTab.TextColor3 = Color3.fromRGB(255, 255, 255)    
    trickTab.TextSize = 16    
    trickTab.Parent = tabFrame    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = trickTab    
        local s = Instance.new('UIStroke'); s.Color = Color3.fromRGB(255,255,255); s.Thickness = 1.5; s.Transparency = 0.1; s.Parent = trickTab    
        tabTextStroke:Clone().Parent = trickTab    
    end    
  
    trickContent = Instance.new('Frame')    
    trickContent.Size = UDim2.new(1, 0, 1, -55)    
    trickContent.Position = UDim2.new(0, 0, 0, 55)    
    trickContent.BackgroundTransparency = 1    
    trickContent.Visible = false    
    trickContent.Parent = mainFrame    
  
    trickTab.MouseButton1Click:Connect(function() switchTab('tricks') end)    
  
    local trickInfoLabel = Instance.new('TextLabel')    
    trickInfoLabel.Size = UDim2.new(0.45, 0, 0, 22)    
    trickInfoLabel.Position = UDim2.new(0.04, 0, 0, 4)    
    trickInfoLabel.BackgroundTransparency = 1    
    trickInfoLabel.Text = 'Equipped pet tricks'    
    trickInfoLabel.Font = Enum.Font.FredokaOne    
    trickInfoLabel.TextSize = 12    
    trickInfoLabel.TextXAlignment = Enum.TextXAlignment.Left    
    trickInfoLabel.TextColor3 = Color3.fromRGB(180, 180, 220)    
    trickInfoLabel.Parent = trickContent    
  
    local unlockAllBtn = Instance.new('TextButton')    
    unlockAllBtn.Size = UDim2.new(0.38, 0, 0, 22)    
    unlockAllBtn.Position = UDim2.new(0.5, 0, 0, 4)    
    unlockAllBtn.Text = '🔓 Unlock All'    
    unlockAllBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)    
    unlockAllBtn.BackgroundTransparency = 0.1    
    unlockAllBtn.Font = Enum.Font.FredokaOne    
    unlockAllBtn.TextSize = 11    
    unlockAllBtn.TextColor3 = Color3.fromRGB(180, 255, 200)    
    unlockAllBtn.Parent = trickContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,5); c.Parent = unlockAllBtn    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(100,255,150); s.Thickness = 1.2; s.Transparency = 0.2; s.Parent = unlockAllBtn    
    end    
  
    local refreshTrickBtn = Instance.new('TextButton')    
    refreshTrickBtn.Size = UDim2.new(0.1, 0, 0, 22)    
    refreshTrickBtn.Position = UDim2.new(0.89, 0, 0, 4)    
    refreshTrickBtn.Text = '↻'    
    refreshTrickBtn.BackgroundColor3 = Color3.fromRGB(60, 45, 90)    
    refreshTrickBtn.BackgroundTransparency = 0.1    
    refreshTrickBtn.Font = Enum.Font.FredokaOne    
    refreshTrickBtn.TextSize = 14    
    refreshTrickBtn.TextColor3 = Color3.fromRGB(180, 150, 255)    
    refreshTrickBtn.Parent = trickContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,5); c.Parent = refreshTrickBtn    
        local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
        s.Color = Color3.fromRGB(150,100,255); s.Thickness = 1.2; s.Transparency = 0.2; s.Parent = refreshTrickBtn    
    end    
  
    local trickScroll = Instance.new('ScrollingFrame')    
    trickScroll.Size = UDim2.new(0.92, 0, 1, -32)    
    trickScroll.Position = UDim2.new(0.04, 0, 0, 30)    
    trickScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 35)    
    trickScroll.BackgroundTransparency = 0.3    
    trickScroll.BorderSizePixel = 0    
    trickScroll.ScrollBarThickness = 4    
    trickScroll.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 255)    
    trickScroll.CanvasSize = UDim2.new(0, 0, 0, 0)    
    trickScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y    
    trickScroll.Parent = trickContent    
    do    
        local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,8); c.Parent = trickScroll    
        local s = Instance.new('UIStroke'); s.Color = Color3.fromRGB(120,80,200); s.Thickness = 1.5; s.Transparency = 0.2; s.Parent = trickScroll    
        local pad = Instance.new('UIPadding')    
        pad.PaddingTop = UDim.new(0,4); pad.PaddingBottom = UDim.new(0,4)    
        pad.PaddingLeft = UDim.new(0,4); pad.PaddingRight = UDim.new(0,4)    
        pad.Parent = trickScroll    
        local l = Instance.new('UIListLayout')    
        l.SortOrder = Enum.SortOrder.LayoutOrder    
        l.Padding = UDim.new(0,3)    
        l.Parent = trickScroll    
    end    
  
    local noTrickLabel = Instance.new('TextLabel')    
    noTrickLabel.Size = UDim2.new(1, 0, 0, 40)    
    noTrickLabel.BackgroundTransparency = 1    
    noTrickLabel.Text = 'Equip a pet to see tricks!'    
    noTrickLabel.Font = Enum.Font.FredokaOne    
    noTrickLabel.TextSize = 13    
    noTrickLabel.TextColor3 = Color3.fromRGB(160, 160, 200)    
    noTrickLabel.TextXAlignment = Enum.TextXAlignment.Center    
    noTrickLabel.LayoutOrder = 1    
    noTrickLabel.Parent = trickScroll    
  
    local function makeTrickButton(i, trickName, animName, petName, scroll)    
        local btn = Instance.new('TextButton')    
        btn.Size = UDim2.new(1, 0, 0, 28)    
        btn.BackgroundColor3 = Color3.fromRGB(50, 40, 75)    
        btn.BackgroundTransparency = 0.1    
        btn.Text = '✦ ' .. trickName    
        btn.Font = Enum.Font.FredokaOne    
        btn.TextSize = 13    
        btn.TextColor3 = Color3.fromRGB(210, 180, 255)    
        btn.TextXAlignment = Enum.TextXAlignment.Left    
        btn.LayoutOrder = i + 1    
        btn.Parent = scroll    
        do    
            local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0,6); c.Parent = btn    
            local s = Instance.new('UIStroke'); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
            s.Color = Color3.fromRGB(150,100,255); s.Thickness = 1.2; s.Transparency = 0.3; s.Parent = btn    
            local p = Instance.new('UIPadding'); p.PaddingLeft = UDim.new(0,8); p.Parent = btn    
        end    
        btn.MouseEnter:Connect(function()    
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(75,55,115)}):Play()    
        end)    
        btn.MouseLeave:Connect(function()    
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(50,40,75)}):Play()    
        end)    
        btn.MouseButton1Click:Connect(function()    
            local ok = doTrick(animName)    
            if ok then    
                game.StarterGui:SetCore('SendNotification', {    
                    Title = '🎪 ' .. trickName,    
                    Text = petName .. ' performs: ' .. trickName,    
                    Duration = 2,    
                })    
            end    
        end)    
    end    
  
    local function buildTrickList()    
        for _, c in ipairs(trickScroll:GetChildren()) do    
            if c:IsA('TextButton') then c:Destroy() end    
        end    
        local entities = PetEntityManager.get_local_owned_pet_entities()    
        if not entities or #entities == 0 then    
            noTrickLabel.Text = 'Equip a pet to see tricks!'    
            noTrickLabel.Visible = true    
            return    
        end    
        local entity = entities[#entities]    
        local tricks = entity.base.entry and entity.base.entry.tricks    
        if not tricks or #tricks == 0 then    
            noTrickLabel.Text = 'This pet has no tricks yet!'    
            noTrickLabel.Visible = true    
            return    
        end    
        noTrickLabel.Visible = false    
        local petName = entity.base.entry and entity.base.entry.name or 'Pet'    
        for i, trick in ipairs(tricks) do    
            local trickName = trick[1]    
            local animName = trick[2]    
            if AnimationManager2.animations[animName] then    
                makeTrickButton(i, trickName, animName, petName, trickScroll)    
            end    
        end    
    end    
  
    unlockAllBtn.MouseButton1Click:Connect(function()    
        unlockAllTricksOnInterface()    
        game.StarterGui:SetCore('SendNotification', { Title='🔓 Unlocked!', Text='All tricks unlocked on interface!', Duration=3 })    
        task.wait(0.5)    
        buildTrickList()    
    end)    
  
    refreshTrickBtn.MouseButton1Click:Connect(buildTrickList)    
    trickTab.MouseButton1Click:Connect(buildTrickList)    
  
    PetEntityManager.get_local_owned_pet_entity_updated_signal():Connect(function()    
        if trickContent.Visible then buildTrickList() end    
    end)    
  
    -- ****──**** Dragging ****──****    
    local dragging, dragStart, startPos    
  
    mainFrame.InputBegan:Connect(function(input)    
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then    
            dragging = true    
            dragStart = input.Position    
            startPos = mainFrame.Position    
            input.Changed:Connect(function()    
                if input.UserInputState == Enum.UserInputState.End then dragging = false end    
            end)    
        end    
    end)    
  
    mainFrame.InputChanged:Connect(function(input)    
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then    
            local delta = input.Position - dragStart    
            mainFrame.Position = UDim2.new(    
                startPos.X.Scale, startPos.X.Offset + delta.X,    
                startPos.Y.Scale, startPos.Y.Offset + delta.Y    
            )    
        end    
    end)    
  
    local function loadInMainFrame()    
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)    
        TweenService:Create(mainFrame, tweenInfo, { Size=UDim2.new(0, 320, 0, 441) }):Play()    
        TweenService:Create(mainFrame, tweenInfo, { BackgroundTransparency=0 }):Play()    
    end    
    loadInMainFrame()    
  
end) -- This closes the initial task.spawn  
