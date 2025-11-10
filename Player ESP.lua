local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local esp_table = {
    __loaded = false,
    main_settings = {
        textSize = 15,
        textFont = Drawing.Fonts.Monospace,
        distancelimit = false,
        maxdistance = 1000,
        useteamcolor = false,
        teamcheck = false,
        sleepcheck = true,
        simplecalc = true
    },
    settings = {
        enemy = {
            enabled = true,
            box = true,
            box_fill = true,
            realname = true,
            dist = true,
            weapon = true,
            skeleton = true,
            tracers = true,
            box_outline = true,
            realname_outline = true,
            dist_outline = true,
            weapon_outline = true,
            box_color = { Color3.new(1, 1, 1), 1 },
            box_fill_color = { Color3.new(1, 0, 0), 0.3 },
            realname_color = { Color3.new(1, 1, 1), 1 },
            dist_color = { Color3.new(1, 1, 1), 1 },
            weapon_color = { Color3.new(1, 1, 1), 1 },
            skeleton_color = { Color3.new(1, 1, 1), 1 },
            tracer_color = { Color3.new(1, 1, 1), 1 },
            box_outline_color = { Color3.new(0, 0, 0), 1 },
            realname_outline_color = Color3.new(0, 0, 0),
            dist_outline_color = Color3.new(0, 0, 0),
            weapon_outline_color = Color3.new(0, 0, 0),
            chams = true,
            chams_visible_only = false,
            chams_fill_color = { Color3.new(1, 1, 1), 0.5 },
            chamsoutline_color = { Color3.new(1, 1, 1), 0 }
        }
    }
}

local container = Instance.new("Folder", CoreGui.RobloxGui)
container.Name = "ESPContainer"

local skeleton_order = {
    ["LeftFoot"] = "LeftLowerLeg", ["LeftLowerLeg"] = "LeftUpperLeg", ["LeftUpperLeg"] = "LowerTorso",
    ["RightFoot"] = "RightLowerLeg", ["RightLowerLeg"] = "RightUpperLeg", ["RightUpperLeg"] = "LowerTorso",
    ["LeftHand"] = "LeftLowerArm", ["LeftLowerArm"] = "LeftUpperArm", ["LeftUpperArm"] = "Torso",
    ["RightHand"] = "RightLowerArm", ["RightLowerArm"] = "RightUpperArm", ["RightUpperArm"] = "Torso",
    ["LowerTorso"] = "Torso", ["Torso"] = "Head"
}

local GetFunction = function(Script, Line)
    for _, v in pairs(getgc()) do
        if typeof(v) == "function" and debug.info(v, "sl") then
            local src, lineNum = debug.info(v, "s"), debug.info(v, "l")
            if src:find(Script) and lineNum == Line then
                return v
            end
        end
    end
    return nil
end

local SetInfraredEnabled = GetFunction("PlayerClient", 588)
local PlayerReg = SetInfraredEnabled and debug.getupvalue(SetInfraredEnabled, 2) or {}

local function worldToScreen(world)
    local screen, inBounds = Camera:WorldToViewportPoint(world)
    return Vector2.new(math.floor(screen.X), math.floor(screen.Y)), inBounds, screen.Z
end

local function calculateCornersSimple(head, hrp)
    local head_position = worldToScreen(head.Position - Vector3.new(0, 0.5, 0))
    local leg_position = worldToScreen(hrp.Position - Vector3.new(0, 3.5, 0))
    local headx, heady = head_position.X, head_position.Y
    local legx, legy = leg_position.X, leg_position.Y
    local height = legy - heady
    local width = height / 3.6
    return {
        topLeft = Vector2.new(headx - width, heady),
        topRight = Vector2.new(headx + width, heady),
        bottomLeft = Vector2.new(headx - width, legy),
        bottomRight = Vector2.new(headx + width, legy)
    }
end

local function getRainbowColor()
    local time = tick() * 0.5
    local r = (math.sin(time) + 1) / 2
    local g = (math.sin(time + 2 * math.pi / 3) + 1) / 2
    local b = (math.sin(time + 4 * math.pi / 3) + 1) / 2
    return Color3.new(r, g, b)
end

local loaded_plrs = {}
local esp = {
    create_obj = function(type, args)
        local obj = Drawing.new(type)
        for i, v in args do
            obj[i] = v
        end
        return obj
    end
}

local function getPlayerIdFromModel(model)
    if not model then return nil, false end
    for _, player in next, PlayerReg do
        if player and player.model == model then
            return player.id, player.sleeping
        end
    end
    local plr = Players:GetPlayerFromCharacter(model)
    return plr and plr.UserId, false
end

local function create_player_esp(model)
    if not (model and model:FindFirstChild("Head") and model:FindFirstChild("LowerTorso")) then
        return
    end
    local player = Players:GetPlayerFromCharacter(model)
    local settings = esp_table.settings.enemy
    local playerId, isSleeping = getPlayerIdFromModel(model)
    local playerName = player and player.Name or "Player"
    loaded_plrs[model] = {
        obj = {
            box_fill = esp.create_obj("Square", { Filled = true, Visible = false }),
            box_outline = esp.create_obj("Square", { Filled = false, Thickness = 3, Visible = false, ZIndex = -1 }),
            box = esp.create_obj("Square", { Filled = false, Thickness = 1, Visible = false }),
            realname = esp.create_obj("Text", { Center = true, Visible = settings.realname }),
            tracer = esp.create_obj("Line", { Thickness = 1, Visible = false })
        },
        chams_object = Instance.new("Highlight", container),
        weapon_esp = playerId and esp.create_obj("Text", {
            Text = "[NONE]",
            Size = 17,
            Color = getRainbowColor(),
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Center = true,
            Visible = false
        }) or nil,
        dist_esp = playerId and esp.create_obj("Text", {
            Text = "0",
            Size = 17,
            Color = getRainbowColor(),
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Center = true,
            Visible = false
        }) or nil
    }
    for required, _ in next, skeleton_order do
        loaded_plrs[model].obj["skeleton_" .. required] = esp.create_obj("Line", { Visible = false })
    end

    if isSleeping then
        loaded_plrs[model].chams_object.Enabled = false
    else
        loaded_plrs[model].chams_object.Enabled = settings.chams
    end

    local character = model
    local head = model:FindFirstChild("Head")
    local lowertorso = model:FindFirstChild("LowerTorso")
    local plr = loaded_plrs[model]
    local obj = plr.obj
    local cham = plr.chams_object
    local weapon_esp = plr.weapon_esp
    local dist_esp = plr.dist_esp

    local function forceupdate()
        if not (obj and cham) then return end
        local rainbowColor = getRainbowColor()
        cham.DepthMode = settings.chams_visible_only and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
        cham.FillColor = rainbowColor
        cham.FillTransparency = settings.chams_fill_color[2]
        cham.OutlineColor = rainbowColor
        cham.OutlineTransparency = settings.chamsoutline_color[2]

        obj.box.Transparency = settings.box_color[2]
        obj.box.Color = rainbowColor
        obj.box_outline.Transparency = settings.box_outline_color[2]
        obj.box_outline.Color = settings.box_outline_color[1]
        obj.box_fill.Color = rainbowColor
        obj.box_fill.Transparency = settings.box_fill_color[2]

        obj.realname.Size = esp_table.main_settings.textSize
        obj.realname.Font = esp_table.main_settings.textFont
        obj.realname.Color = rainbowColor
        obj.realname.Outline = settings.realname_outline
        obj.realname.OutlineColor = settings.realname_outline_color
        obj.realname.Transparency = settings.realname_color[2]

        obj.tracer.Color = rainbowColor
        obj.tracer.Transparency = settings.tracer_color[2]

        if weapon_esp then weapon_esp.Color = rainbowColor end
        if dist_esp then dist_esp.Color = rainbowColor end

        cham.Enabled = not isSleeping and settings.chams
        obj.box.Visible = not isSleeping and settings.box
        obj.box_outline.Visible = not isSleeping and settings.box_outline
        obj.box_fill.Visible = not isSleeping and settings.box_fill
        obj.realname.Visible = settings.realname
        obj.tracer.Visible = not isSleeping and settings.tracers
        if weapon_esp then weapon_esp.Visible = not isSleeping and settings.weapon end
        if dist_esp then dist_esp.Visible = not isSleeping and settings.dist end

        for required, _ in next, skeleton_order do
            local skeletonobj = obj["skeleton_" .. required]
            if skeletonobj then
                skeletonobj.Color = rainbowColor
                skeletonobj.Transparency = settings.skeleton_color[2]
                skeletonobj.Visible = not isSleeping and settings.skeleton
            end
        end
    end

    local function togglevis(bool)
        if not obj then return end
        for _, v in obj do
            if v and v.Visible ~= nil then
                v.Visible = bool and (v == obj.realname or not isSleeping)
            end
        end
        if cham then
            cham.Enabled = bool and not isSleeping and settings.chams
        end
        if weapon_esp then weapon_esp.Visible = bool and not isSleeping and settings.weapon end
        if dist_esp then dist_esp.Visible = bool and not isSleeping and settings.dist end
        for required, _ in next, skeleton_order do
            local skeletonobj = obj["skeleton_" .. required]
            if skeletonobj then
                skeletonobj.Visible = bool and not isSleeping and settings.skeleton
            end
        end
    end

    plr.connection = RunService.RenderStepped:Connect(function()
        if not (head and character and lowertorso) then
            togglevis(false)
            return
        end
        local _, onScreen = worldToScreen(head.Position)
        if not onScreen then
            togglevis(false)
            return
        end

        local distance = (Camera.CFrame.Position - head.Position).Magnitude
        if esp_table.main_settings.distancelimit and distance > esp_table.main_settings.maxdistance then
            togglevis(false)
            return
        end

        local currentPlayerId, isSleeping = getPlayerIdFromModel(model)
        if currentPlayerId ~= playerId or isSleeping ~= plr.isSleeping then
            plr.isSleeping = isSleeping
            togglevis(false)
            if isSleeping then
                obj.realname.Text = "Sleeper"
                obj.realname.Visible = settings.realname
            else
                local player = Players:GetPlayerFromCharacter(character)
                obj.realname.Text = player and player.Name or "Player"
            end
            return
        end

        togglevis(true)
        cham.Adornee = character
        forceupdate()

        local corners = calculateCornersSimple(head, lowertorso)
        if not corners then
            togglevis(false)
            return
        end

        local pos = corners.topLeft
        local size = corners.bottomRight - corners.topLeft
        obj.box.Position = pos
        obj.box.Size = size
        obj.box_outline.Position = pos + Vector2.new(1, 1)
        obj.box_outline.Size = size - Vector2.new(1, 1)
        obj.box_fill.Position = pos
        obj.box_fill.Size = size

        obj.realname.Position = corners.topLeft + (corners.topRight - corners.topLeft) / 2 - Vector2.new(0, obj.realname.TextBounds.Y + 2)

        if not isSleeping then
            local bottom = (corners.bottomLeft + corners.bottomRight) * 0.5
            if playerId and weapon_esp and dist_esp then
                local playerData = nil
                for _, v in next, PlayerReg do
                    if v and v.id == playerId and not v.sleeping then
                        playerData = v
                        break
                    end
                end
                if playerData then
                    local WeaponFound = playerData.equippedItem and playerData.equippedItem.type or "None"
                    weapon_esp.Text = "[" .. WeaponFound:lower() .. "]"
                    weapon_esp.Position = bottom + Vector2.new(0, 2)
                    dist_esp.Text = tostring(math.floor(distance))
                    dist_esp.Position = bottom + Vector2.new(0, weapon_esp.TextBounds.Y + 4)
                end
            end
        end

        if settings.skeleton then
            for _, part in next, character:GetChildren() do
                local skeletonobj = obj["skeleton_" .. part.Name]
                local parent_part = skeleton_order[part.Name] and character:FindFirstChild(skeleton_order[part.Name])
                if skeletonobj and parent_part then
                    local part_position, _ = Camera:WorldToViewportPoint(part.Position)
                    local parent_part_position, _ = Camera:WorldToViewportPoint(parent_part.CFrame.Position)
                    skeletonobj.From = Vector2.new(part_position.X, part_position.Y)
                    skeletonobj.To = Vector2.new(parent_part_position.X, parent_part_position.Y)
                end
            end
        end

        if settings.tracers then
            local torsoPos, onScreenTorso = worldToScreen(lowertorso.Position)
            if onScreenTorso then
                local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                obj.tracer.From = screenCenter
                obj.tracer.To = torsoPos
            else
                obj.tracer.Visible = false
            end
        end
    end)

    forceupdate()
end

local function destroy_esp(model)
    local plr_object = loaded_plrs[model]
    if not plr_object then return end
    plr_object.connection:Disconnect()
    for _, v in plr_object.obj do
        if v then v:Remove() end
    end
    if plr_object.chams_object then
        plr_object.chams_object:Destroy()
    end
    if plr_object.weapon_esp then plr_object.weapon_esp:Remove() end
    if plr_object.dist_esp then plr_object.dist_esp:Remove() end
    loaded_plrs[model] = nil
end

function esp_table.load()
    if esp_table.__loaded then return end
    for _, v in next, workspace:GetChildren() do
        if v:IsA("Model") then
            task.spawn(function()
                task.wait(0.5)
                create_player_esp(v)
            end)
        end
    end
    esp_table.playerAdded = Players.PlayerAdded:Connect(function(player)
        print("New player joined: " .. player.Name)
        player.CharacterAdded:Connect(function(character)
            print("Character added for: " .. player.Name)
            task.spawn(function()
                task.wait(0.5)
                create_player_esp(character)
            end)
        end)
    end)
    esp_table.playerRemoving = workspace.ChildRemoved:Connect(destroy_esp)
    esp_table.__loaded = true
end

function esp_table.unload()
    if not esp_table.__loaded then return end
    for _, v in next, workspace:GetChildren() do
        destroy_esp(v)
    end
    esp_table.playerAdded:Disconnect()
    esp_table.playerRemoving:Disconnect()
    esp_table.__loaded = false
end

esp_table.load()
