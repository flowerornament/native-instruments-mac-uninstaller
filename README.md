# Native Instruments Mac Uninstaller

Vibe-coded shell script to safely uninstall Native Instruments content on Mac ✨

## Back-story

For years I've had various broken Native Instruments packages on my machines unable to be repaired or removed by the Native Access app.
As far as I can tell, this script safely removes any app, instrument, or effect you want.

## Features

- Multiple operation modes (interactive, automatic, verbose)
- Moves files to the trash instead of permanently deleting them
- Confirms before each deletion to prevent accidents
- Pretty colors and progress indicators
- Detailed log file of all actions taken
- Finds content on external drives (optional)

## How to use

1. Download `ni-uninstaller.sh`
2. Make it executable: `chmod +x ni-uninstaller.sh`
3. Run with sudo: `sudo ./ni-uninstaller.sh`
4. Follow the friendly prompts!

## Requirements

- macOS 10.9 or later
- Sudo privileges

## Safety first!

This script is provided as-is. Always back up important content before uninstalling.
