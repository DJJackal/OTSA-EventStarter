local currentEvent = nil

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function drawText(text, x, y, scale, r, g, b, a, font)
    SetTextFont(font or 4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function clearCurrentEvent(eventId)
    if currentEvent and currentEvent.id == eventId then
        currentEvent = nil
    end
end

local function teleportTo(destination)
    CreateThread(function()
        local playerPed = PlayerPedId()

        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        RequestCollisionAtCoord(destination.x, destination.y, destination.z)
        SetEntityCoordsNoOffset(playerPed, destination.x, destination.y, destination.z + 0.5, false, false, false)
        SetEntityHeading(playerPed, destination.heading or 0.0)
        FreezeEntityPosition(playerPed, true)

        Wait(Config.TeleportFreezeMs)

        FreezeEntityPosition(playerPed, false)
        DoScreenFadeIn(250)
    end)
end

RegisterNetEvent('otsa-eventstarter:client:startEvent', function(eventId, duration, eventName)
    currentEvent = {
        id = eventId,
        expiresAt = GetGameTimer() + duration,
        eventName = eventName or ''
    }
end)

RegisterNetEvent('otsa-eventstarter:client:endEvent', function(eventId)
    clearCurrentEvent(eventId)
end)

RegisterNetEvent('otsa-eventstarter:client:notification', function(message)
    notify(message)
end)

RegisterNetEvent('otsa-eventstarter:client:teleportToStarter', function(eventId, destination)
    if not currentEvent or currentEvent.id ~= eventId then
        return
    end

    clearCurrentEvent(eventId)
    teleportTo(destination)
end)

RegisterNetEvent('otsa-eventstarter:client:returnToOriginalPosition', function(_, destination)
    teleportTo(destination)
end)

RegisterCommand(Config.JoinCommand, function()
    if not currentEvent then
        return
    end

    if GetGameTimer() >= currentEvent.expiresAt then
        currentEvent = nil
        return
    end

    TriggerServerEvent('otsa-eventstarter:server:joinEvent', currentEvent.id)
end, false)

RegisterCommand('-otsa_event_join', function()
    -- Required by FiveM's key mapping system.
end, false)

RegisterKeyMapping(Config.JoinCommand, Config.JoinKeyDescription, 'keyboard', Config.DefaultJoinKey)

CreateThread(function()
    while true do
        if currentEvent and GetGameTimer() < currentEvent.expiresAt then
            Wait(0)

            -- Top-centre announcement panel.
            DrawRect(0.5, 0.125, 0.57, 0.135, 0, 0, 0, 175)
            DrawRect(0.5, 0.067, 0.57, 0.006, 220, 35, 35, 235)

            local title = 'AN EVENT IS STARTING SHORTLY'
            if currentEvent.eventName ~= '' then
                title = ('%s EVENT IS STARTING SHORTLY'):format(string.upper(currentEvent.eventName))
            end

            -- Named events can be longer than the default heading, so gently
            -- reduce the scale while keeping the announcement in the top centre.
            local titleScale = 0.54
            if #title > 42 then
                titleScale = 0.42
            elseif #title > 34 then
                titleScale = 0.47
            end

            drawText(title, 0.5, 0.082, titleScale, 255, 255, 255, 255, 4)
            drawText('If you would like to be a part of it, push ~y~F5~s~ NOW!', 0.5, 0.122, 0.38, 255, 255, 255, 255, 4)
            drawText('Otherwise, please disregard this message.', 0.5, 0.153, 0.34, 225, 225, 225, 255, 4)
        else
            if currentEvent then
                currentEvent = nil
            end

            Wait(500)
        end
    end
end)
