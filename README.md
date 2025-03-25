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

## Sample Output

When you run the script, it looks something like this:

```console
Native Instruments Uninstaller v2.0 for macOS
This script will move Native Instruments files to the Trash.
Files can be recovered from the Trash if needed.

Enter the name of the Native Instruments product to uninstall:
Kontakt 7

Will uninstall: Kontakt 7

Continue with uninstallation? [y/N]
y

Select operation mode:
1. Interactive - Confirm each file removal
2. Automatic - Remove all files without confirmation
3. Verbose automatic - Show all files but remove without confirmation
Enter your choice [1-3]: 1

Interactive mode selected. You will confirm each file removal.

Starting uninstallation process...

=== CHECKING APPLICATIONS ===
Found application: /Applications/Native Instruments/Kontakt 7.app (Size: 1.2G)
Move to Trash? [y/n]
y
Moving to Trash...

=== CHECKING SYSTEM LIBRARY LOCATIONS ===
Found preferences: /Library/Preferences/com.native-instruments.kontakt7.plist
Move to Trash? [y/n]
y
Moving to Trash...

Found plugin: /Library/Audio/Plug-Ins/Components/Kontakt 7.component (Size: 44M)
Move to Trash? [y/n]
y
Moving to Trash...

Found plugin: /Library/Audio/Plug-Ins/VST/Kontakt 7.vst (Size: 42M)
Move to Trash? [y/n]
y
Moving to Trash...

Found plugin: /Library/Audio/Plug-Ins/VST3/Kontakt 7.vst3 (Size: 46M)
Move to Trash? [y/n]
y
Moving to Trash...

=== CHECKING USER LIBRARY LOCATIONS ===
Found preferences: /Users/flowerornament/Library/Preferences/com.native-instruments.kontakt7.plist
Move to Trash? [y/n]
y
Moving to Trash...

Found support files: /Users/flowerornament/Library/Application Support/Native Instruments/Kontakt 7 (Size: 124M)
Move to Trash? [y/n]
y
Moving to Trash...

=== CHECKING PRODUCT REGISTRY ===
Found registry: /Library/Application Support/Native Instruments/Service Center/Kontakt 7.xml
Move to Trash? [y/n]
y
Moving to Trash...

Found registry: /Users/Shared/Native Instruments/installed_products/Kontakt 7.json
Move to Trash? [y/n]
y
Moving to Trash...

Do you want to check for content libraries? [y/n]
y

=== CONTENT LIBRARIES ===
Found content: /Users/Shared/Native Instruments/Kontakt 7 (Size: 4.8G)
Move to Trash? [y/n]
y
Moving to Trash...

Check external drives for content? [y/n]
y

CHECKING EXTERNAL DRIVES
Found external content: /Volumes/SampleDrive/Native Instruments/Kontakt 7 (Size: 120G)
Move to Trash? [y/n]
n
Skipped by user

Uninstallation process completed!

=== SUMMARY ===
  ✓ Moved 1 application files to Trash
  ✓ Moved 5 system library files to Trash
  ✓ Moved 2 user library files to Trash
  ✓ Moved 2 product registry files to Trash
  ✓ Moved 1 content library files to Trash
  ○ No content found on external drives
Total items moved to Trash: 11
A log file has been saved to: /Users/flowerornament/Desktop/NI_Uninstall_2025-03-25_14-22-33.log

Files have been moved to the Trash.
You can restore them if needed, or empty the Trash to permanently delete them.
```
