# OTSA-EventStarter

OTSA-EventStarter is a lightweight standalone FiveM event utility for vMenu and other ACE-based servers. It lets authorised staff announce a server-wide event, gives players a temporary F5 join prompt, teleports participants to the event starter, and returns them to their original positions when the event ends.

## Features

- Standalone resource with no framework dependency.
- ACE permission protected staff commands.
- Optional event names in server-wide announcements.
- Configurable join window duration.
- F5 join key with FiveM key mapping support, so players can rebind it.
- Saves participant coordinates and heading server-side before teleporting.
- Returns connected participants to their original positions when the event finishes.
- Automatically restores participants if the event starter disconnects.
- Prevents multiple event sessions from running at the same time.
- Sanitises event names before broadcasting them to clients.

## Requirements

- A FiveM server with OneSync enabled.
- An ACE permission setup that grants authorised staff the permission configured in `config.lua`.

No ESX, QBCore, Discord API, or other framework is required.

## Installation

1. Download or clone this repository.
2. Place the `OTSA-EventStarter` folder in your server's `resources` directory.
3. Add the resource to `server.cfg`:

```cfg
ensure OTSA-EventStarter
```

4. Grant your staff group permission to start and finish events:

```cfg
add_ace group.admin otsa.eventstarter allow
```

If you prefer to grant the permission directly to a FiveM license identifier, you can use a placeholder like this and replace it with the real identifier on your own server:

```cfg
add_ace identifier.license:YOUR_LICENSE_HERE otsa.eventstarter allow
```

5. Restart the server or run `ensure OTSA-EventStarter` from the server console.

## Commands

| Command | Description |
| --- | --- |
| `/eventstart` | Starts an unnamed event and opens the join window. |
| `/eventstart <event name>` | Starts an event with a custom announcement name. |
| `/eventfinish` | Ends the current event and returns connected participants. |

Only the same authorised staff member who started the event can use `/eventfinish` for that session.

## Player joining

While the announcement is displayed, players can press **F5** to join the active event.

FiveM exposes this through its key mapping system, so players can rebind the key in their FiveM settings.

When a player joins:

1. Their current coordinates and heading are saved server-side.
2. The current coordinates and heading of the event starter are read server-side.
3. The participant is teleported to the event starter.
4. Their saved location remains stored until the event ends or they disconnect.

When `/eventfinish` is used, every connected participant is returned to their saved position.

## Configuration

All main settings are in `config.lua`.

```lua
Config.Command = 'eventstart'
Config.FinishCommand = 'eventfinish'
Config.AcePermission = 'otsa.eventstarter'

Config.AnnouncementDuration = 20000
Config.MaxEventNameLength = 32

Config.JoinCommand = '+otsa_event_join'
Config.JoinKeyDescription = 'Join active OTSA event'
Config.DefaultJoinKey = 'F5'

Config.TeleportFreezeMs = 750
```

### Announcement duration

`Config.AnnouncementDuration` is measured in milliseconds. The default value of `20000` gives players 20 seconds to join.

### Event names

Event names are optional and limited by `Config.MaxEventNameLength`. FiveM formatting characters and line breaks are stripped before the name is broadcast.

Example:

```text
/eventstart speedway racing
```

Players will see:

```text
SPEEDWAY RACING EVENT IS STARTING SHORTLY
```

### ACE permission

The server checks:

```lua
IsPlayerAceAllowed(source, Config.AcePermission)
```

This means the resource works with any staff or Discord permission system that ultimately grants the configured ACE permission.

## Behaviour and safety

- Only one event session can exist at a time.
- The console cannot start or finish an event because the system is tied to the in-game player who initiated it.
- If the event starter disconnects, connected participants are automatically returned to their saved positions.
- If a participant disconnects before the event finishes, they cannot be teleported back because they are no longer connected, and their saved session data is discarded.
- Coordinate lookups happen server-side before each teleport.

## Version

Current resource version: **1.2.0**

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## Contributing

Issues and pull requests are welcome. For bug reports, include reproduction steps, your FiveM server build, and any relevant console output.

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
