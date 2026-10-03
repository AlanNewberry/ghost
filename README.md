# ghost - WiFi Monitor Mode Tool

A Bash script that puts your WiFi interface into monitor mode with minimal effort. Detects wireless interfaces, validates your channel, kills conflicting processes, and configures the adapter on the channel you pick. Restores your interface on exit (Ctrl+C) or prints restore commands when done.

## What it does

1. Validates root privileges and channel number (1-196).
2. Detects WiFi interfaces via `iw dev`, falls back to `iwconfig`.
3. Shows chipset and driver info for the selected adapter.
4. Kills conflicting processes via `airmon-ng check kill`.
5. Sets monitor mode and the chosen channel.
6. Verifies the channel was actually set correctly.
7. Prints restore commands to get back to managed mode.
8. On Ctrl+C, automatically restores the interface before exiting.

## Requirements

- Linux with Bash 4+
- `iw`, `iwconfig`, `airmon-ng`, `ip`
- Root privileges (run with `sudo`)
- A WiFi adapter that supports monitor mode
- Terminal with UTF-8 support

## Adapter compatibility

Works with any WiFi adapter recognized by `iw` or `iwconfig` that supports monitor mode. Not all USB adapters support monitor mode, so verify your hardware first.

## Usage

Make the script executable (first time only):

```bash
chmod +x ghost.sh
```

Run it as root:

```bash
sudo ./ghost.sh [OPTIONS] [CHANNEL]
```

### Options

| Flag | Description |
|------|-------------|
| `-i IFACE` | Use a specific interface (skip auto-detection) |
| `-c CHANNEL` | Set channel (1-196, default: 6) |
| `-l` | List available WiFi interfaces and exit |
| `-h` | Show help and exit |
| `-v` | Show version and exit |

### Examples

```bash
sudo ./ghost.sh                # channel 6, auto-detect interface
sudo ./ghost.sh 11             # channel 11, auto-detect interface
sudo ./ghost.sh -i wlan0 -c 1  # wlan0, channel 1
sudo ./ghost.sh -l              # list interfaces
```

## Restoring your interface

The script prints restore commands when it finishes. If you press Ctrl+C, it restores the interface automatically. You can also restore manually:

```bash
sudo ip link set wlan0 down
sudo iwconfig wlan0 mode managed
sudo ip link set wlan0 up
```

## Legal notice

This tool is intended exclusively for authorized security testing and educational purposes. Enabling monitor mode and capturing wireless traffic without permission is illegal in most jurisdictions. The author assumes no responsibility for misuse.

## Credits

Developed by Alan Newberry under the alias `44ghost44`.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
