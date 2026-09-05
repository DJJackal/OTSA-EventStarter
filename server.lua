local activeJoinWindow = nil
local activeSession = nil
local nextEventId = 0

local function sendNotification(target, message)
    TriggerClientEvent('otsa-eventstarter:client:notification', target, message)
end

local function getEventName(args)
    local eventName = table.concat(args or {}, ' ')

    -- Keep the on-screen heading safe and compact. The event name is supplied by
    -- an authorised admin through chat, but FiveM text-formatting characters and
    -- line breaks are removed before it is broadcast to every client.
    eventName = eventName:gsub('[\r\n\t]', ' ')
    eventName = eventName:gsub('~', '')
    eventName = eventName:gsub('%s+', ' ')
    eventName = eventName:match('^%s*(.-)%s*$') or ''

    if #eventName > Config.MaxEventNameLength then
        eventName = eventName:sub(1, Config.MaxEventNameLength)
    end

    return eventName
end

local function closeJoinWindow(reason)
    if not activeJoinWindow then
        return
    end

    local eventId = activeJoinWindow.id
    activeJoinWindow = nil
    TriggerClientEvent('otsa-eventstarter:client:endEvent', -1, eventId, reason)
end

local function returnParticipants(session, reason)
    local returnedCount = 0

    for playerSource, originalPosition in pairs(session.participants) do
        local playerPed = GetPlayerPed(playerSource)

        if playerPed ~= 0 then
            TriggerClientEvent('otsa-eventstarter:client:returnToOriginalPosition', playerSource, session.id, originalPosition)
            sendNotification(playerSource, reason)
            returnedCount = returnedCount + 1
        end
    end

    return returnedCount
end

local function finishSession(reason)
    if not activeSession then
        return 0
    end

    local session = activeSession
    activeSession = nil

    if activeJoinWindow and activeJoinWindow.id == session.id then
        closeJoinWindow('The event is ending.')
    end

    return returnParticipants(session, reason)
end

RegisterCommand(Config.Command, function(source, args)
    -- An initiating player is required because participants are teleported to them.
    if source == 0 then
        print(('[OTSA-EventStarter] /%s must be run by an in-game admin.'):format(Config.Command))
        return
    end

    if not IsPlayerAceAllowed(source, Config.AcePermission) then
        sendNotification(source, 'You do not have permission to start an event.')
        return
    end

    if activeSession then
        sendNotification(source, ('An event is already in progress. The starter must use /%s before another event can begin.'):format(Config.FinishCommand))
        return
    end

    local adminPed = GetPlayerPed(source)
    if adminPed == 0 then
        sendNotification(source, 'Your player ped is not available. Please try again.')
        return
    end

    local eventName = getEventName(args)

    nextEventId = nextEventId + 1

    activeSession = {
        id = nextEventId,
        adminSource = source,
        eventName = eventName,
        participants = {}
    }

    activeJoinWindow = {
        id = activeSession.id,
        adminSource = source,
        expiresAt = GetGameTimer() + Config.AnnouncementDuration
    }

    local eventId = activeSession.id

    TriggerClientEvent('otsa-eventstarter:client:startEvent', -1, eventId, Config.AnnouncementDuration, eventName)

    local eventLabel = eventName ~= '' and ('%s event'):format(eventName) or 'Event'
    sendNotification(source, ('%s announcement sent. Players have %d seconds to press F5. When the event is over, use /%s to return participants.'):format(
        eventLabel,
        math.floor(Config.AnnouncementDuration / 1000),
        Config.FinishCommand
    ))

    CreateThread(function()
        Wait(Config.AnnouncementDuration + 100)

        if activeJoinWindow and activeJoinWindow.id == eventId then
            closeJoinWindow('The event join window has closed.')
        end
    end)
end, false)

RegisterCommand(Config.FinishCommand, function(source)
    if source == 0 then
        print(('[OTSA-EventStarter] /%s must be run by the in-game admin who started the event.'):format(Config.FinishCommand))
        return
    end

    if not IsPlayerAceAllowed(source, Config.AcePermission) then
        sendNotification(source, 'You do not have permission to finish an event.')
        return
    end

    if not activeSession then
        sendNotification(source, 'There is no active event to finish.')
        return
    end

    if activeSession.adminSource ~= source then
        sendNotification(source, 'Only the admin who started this event can finish it.')
        return
    end

    local returnedCount = finishSession('The event has finished. You have been returned to your original position.')
    sendNotification(source, ('Event finished. Returned %d participant(s) to their original position.'):format(returnedCount))
end, false)

RegisterNetEvent('otsa-eventstarter:server:joinEvent', function(eventId)
    local source = source

    if type(eventId) ~= 'number' or not activeJoinWindow or not activeSession or activeJoinWindow.id ~= eventId or activeSession.id ~= eventId then
        return
    end

    if GetGameTimer() > activeJoinWindow.expiresAt then
        closeJoinWindow('The event join window has closed.')
        return
    end

    if activeSession.participants[source] then
        return
    end

    local playerPed = GetPlayerPed(source)
    if playerPed == 0 then
        sendNotification(source, 'Your player ped is not available. Please try again.')
        return
    end

    local adminSource = activeSession.adminSource
    local adminPed = GetPlayerPed(adminSource)

    if adminPed == 0 then
        sendNotification(source, 'The event starter is no longer available.')
        finishSession('The event starter is no longer available. You have been returned to your original position.')
        return
    end

    -- Save the participant's location server-side immediately before teleporting.
    -- It is retained until /eventfinish is used by the event starter.
    local originalCoords = GetEntityCoords(playerPed)
    local originalHeading = GetEntityHeading(playerPed)

    local adminCoords = GetEntityCoords(adminPed)
    local adminHeading = GetEntityHeading(adminPed)

    activeSession.participants[source] = {
        x = originalCoords.x,
        y = originalCoords.y,
        z = originalCoords.z,
        heading = originalHeading
    }

    -- Coordinates are obtained server-side immediately before teleporting, so players
    -- arrive at the current location of the admin who started the event.
    TriggerClientEvent('otsa-eventstarter:client:teleportToStarter', source, eventId, {
        x = adminCoords.x,
        y = adminCoords.y,
        z = adminCoords.z,
        heading = adminHeading
    })
end)

AddEventHandler('playerDropped', function()
    local source = source

    if activeJoinWindow and activeJoinWindow.adminSource == source then
        closeJoinWindow('The event starter left the server.')
    end

    if activeSession then
        if activeSession.adminSource == source then
            finishSession('The event starter left the server. You have been returned to your original position.')
            return
        end

        -- A disconnected participant cannot be returned. Their saved position is no longer needed.
        activeSession.participants[source] = nil
    end
end)
