# oxx

`oxx` is a macOS user-level background service that cycles the mouse cursor
through active displays with a middle-click.

## Build

```sh
swift build
```

For LaunchAgent installation, build the service binary first:

```sh
swift build --product oxx-service -c release
swift run oxx install --service-path .build/release/oxx-service
```

## Commands

```sh
swift run oxx list-displays
swift run oxx jump 0
swift run oxx config show
swift run oxx config validate
swift run oxx permissions --prompt
swift run oxx service-permissions
swift run oxx install --service-path .build/release/oxx-service
swift run oxx status
swift run oxx stop
swift run oxx start
swift run oxx uninstall
```

The LaunchAgent is installed at:

```text
~/Library/LaunchAgents/dev.fyn.oxx.plist
```

The config file is:

```text
~/.config/oxx/config.json
```

Default config:

```json
{
  "action" : "cycleNextDisplay",
  "consumeTrigger" : false,
  "ordering" : "leftToRightTopToBottom",
  "trigger" : "middleClick"
}
```

## Permissions

The service uses a global `CGEvent` tap and `CGWarpMouseCursorPosition`, so macOS
must grant Accessibility permission to the running binary:

```text
System Settings > Privacy & Security > Accessibility
```

By default, middle-click is passed through to the active app after cycling the
cursor. Set `consumeTrigger` to `true` if the service should swallow the
middle-click event.

The background service does not repeatedly trigger the macOS permission prompt.
Use `swift run oxx permissions --prompt` when you want to open the prompt, then
restart the service with `swift run oxx restart`.
The service binary is copied to a stable path during install:

```text
~/Applications/oxx-service.app/Contents/MacOS/oxx-service
```
