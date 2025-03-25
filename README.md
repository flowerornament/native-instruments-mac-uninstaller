# Native Instruments Mac Uninstaller

Vibe-coded shell script to safely uninstall Native Instruments content on Mac ✨

## Back-story

For years I've had various Native Instruments packages on my machines in various states of disrepair, unable to be either repaired or removed by the Native Access app. This is a script vibe-coded with Claude that, as far as I can tell, safely removes any app, instrument, or effect you want.

## Good to know

- Rather than `rm -rf`-ing files, this script moves things to the trash
- Prompts you to confirm deletion of files, so you don't accidentally mess something up
- Pretty colors

## How to install

- Download `ni-uninstall.sh`
- `chmod +x` it
- If you don't know how to work with shell scripts, ask Claude for best practices
