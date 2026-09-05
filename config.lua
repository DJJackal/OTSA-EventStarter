Config = {}

-- Command entered by authorised admins in chat to open an event join window.
-- Usage: /eventstart or /eventstart <event name>
Config.Command = 'eventstart'

-- Command entered by the admin who started the event to return participants.
Config.FinishCommand = 'eventfinish'

-- ACE permission required to use /eventstart and /eventfinish.
-- Add this to your server.cfg for the relevant group or identifier:
-- add_ace group.admin otsa.eventstarter allow
Config.AcePermission = 'otsa.eventstarter'

-- Time, in milliseconds, that players can see the prompt and press F5.
Config.AnnouncementDuration = 20000

-- Maximum number of characters accepted after /eventstart for the optional event name.
-- Example: /eventstart speedway racing
Config.MaxEventNameLength = 32

-- Key mapping shown in FiveM key bindings. Players can rebind it in FiveM settings.
Config.JoinCommand = '+otsa_event_join'
Config.JoinKeyDescription = 'Join active OTSA event'
Config.DefaultJoinKey = 'F5'

-- Brief freeze after teleporting so the destination collision can load.
Config.TeleportFreezeMs = 750
