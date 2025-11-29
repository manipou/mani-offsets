local Keybinds, ShellCache = {}, {}

local function ClearCache()
    if DoesEntityExist(ShellCache['ShellEntity']) then DeleteEntity(ShellCache['ShellEntity']) end
end

local function SetKeybindState(state)
    for Keybind = 1, #Keybinds do
        Keybinds[Keybind]:disable(not state)
    end
end

local function RemoveHouse()
    if next(ShellCache) then ClearCache() end

    exports['mani-bridge']:TeleportEntity(cache.ped, ShellCache['OldCoords'])

    SetKeybindState(false)

    lib.hideTextUI()
end

local function CopyCoords()
    if not next(ShellCache) then return end

    local PlayerPed = cache.ped
    local Offset = GetOffsetFromEntityGivenWorldCoords(ShellCache['ShellEntity'], GetEntityCoords(PlayerPed))
    local Heading = GetEntityHeading(PlayerPed)

    local X = string.format("%.2f", Offset.x)
    local Y = string.format("%.2f", Offset.y)
    local Z = string.format("%.2f", (Offset.z -1))
    local W = string.format("%.2f", Heading)
    
    lib.setClipboard(('vec4(%s, %s, %s, %s)'):format(X, Y, Z, W))
end

local function PlacePainting()
    if not next(ShellCache) then return end

    local PlayerPed = cache.ped

    local PaintingModel = GetHashKey('ch_prop_vault_painting_01a')

    lib.requestModel(PaintingModel)

    local StartOffset = GetEntityCoords(PlayerPed) + GetEntityForwardVector(PlayerPed) * 2
    local PaintingEntity = CreateObject(PaintingModel, StartOffset.x, StartOffset.y, StartOffset.z, false, false, false)

    local GizmoData = exports['object_gizmo']:useGizmo(PaintingEntity)

    DeleteEntity(PaintingEntity)

    lib.showTextUI('[E] Copy PlayerOffset  \n  [G] Place Painting  \n  [X] Cancel')
    
    local Offset = GetOffsetFromEntityGivenWorldCoords(ShellCache['ShellEntity'], vec3(GizmoData.position.x, GizmoData.position.y, GizmoData.position.z))
    local Heading = GizmoData.rotation.z

    local X = string.format("%.2f", Offset.x)
    local Y = string.format("%.2f", Offset.y)
    local Z = string.format("%.2f", Offset.z)
    local W = string.format("%.2f", Heading)
    
    lib.setClipboard(('vec4(%s, %s, %s, %s)'):format(X, Y, Z, W))
end

RegisterCommand('shelloffset', function(_, args)
    local ShellName = args[1]
    if not ShellName then exports['mani-bridge']:Notify(locale('Notify.Failed'), locale('Notify.InvalidArgument'), 'error', 5000) return end
    local ShellModel = GetHashKey(ShellName)

    if not IsModelInCdimage(ShellModel) then exports['mani-bridge']:Notify(locale('Notify.Failed'), locale('Notify.InvalidArgument'), 'error', 5000) return end

    if next(ShellCache) then ClearCache() end

    local PlayerPed = cache.ped
    ShellCache['OldCoords'] = ShellCache['OldCoords'] or GetEntityCoords(PlayerPed)

    local ShellCoords = ShellCache['OldCoords'] + vec3(0.0, 0.0, 100.0)
    
    ShellCache['ShellEntity'] = CreateObjectNoOffset(ShellModel, ShellCoords, false, true, false)
    FreezeEntityPosition(ShellCache['ShellEntity'], true)

    exports['mani-bridge']:TeleportEntity(PlayerPed, ShellCoords)

    SetKeybindState(true)

    lib.showTextUI('[E] Copy PlayerOffset  \n  [G] Place Painting  \n  [X] Cancel')
end)

CreateThread(function()
    Keybinds[#Keybinds + 1] = lib.addKeybind({
        name = 'CopyCoords',
        description = 'Press E To Copy Offset Coords',
        defaultKey = 'E',
        disabled = true,
        onPressed = CopyCoords,
    })

    Keybinds[#Keybinds + 1] = lib.addKeybind({
        name = 'PlacePainting',
        description = 'Press G To Place Painting',
        defaultKey = 'G',
        disabled = true,
        onPressed = PlacePainting,
    })

    Keybinds[#Keybinds + 1] = lib.addKeybind({
        name = 'RemoveHouse',
        description = 'Press X To Remove House',
        defaultKey = 'X',
        disabled = true,
        onPressed = RemoveHouse,
    })
end)