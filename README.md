Windows-Audio-Device-Switcher (DualAudioDefaults.ps1)
Solves the common Windows issue where changing the audio output device from the quick settings panel (system tray) only updates the "Default Device" and not the "Default Communication Device," which can cause applications like Discord to use an unintended audio output. This PowerShell script allows setting both defaults simultaneously, toggling between two configurable audio setups, and provides sound feedback. It's designed for easy integration with PowerToys for quick keyboard shortcut access.

Disclaimer / User Note
This script was developed to solve a specific audio management issue for its initial user. While it has been tested and used successfully by its initial user, please note that the initial user has not extensively reviewed the internal code workings or this detailed README. The script was developed with the assistance of AI. Users should understand the script's functionality and prerequisites before use.

Features
Synchronized Defaults: Sets both the Windows Default Playback Device and Default Communication Device simultaneously.

Device Toggling: Quickly toggle between two predefined audio output setups with a single command or shortcut.

List Audio Devices: Display a list of available playback audio devices with their names, IDs, and current default status.

Specific Device Setting: Set a specific audio device as the default for both roles using its name or ID.

Configurable Sound Notifications:

Plays sounds before attempting a device change and after a successful change.

Plays an error sound if an operation fails.

Supports custom .wav files (recommended, plays synchronously) or built-in Windows system sounds ("Asterisk", "Beep", "Exclamation", "Hand", "Question").

Custom sound files can be placed in a Sound subdirectory relative to the script for portability.

Automatic Module Installation: Attempts to install the required AudioDeviceCmdlets PowerShell module if not already present.

PowerToys Integration: Designed to be easily triggered by a keyboard shortcut using PowerToys Keyboard Manager.

Prerequisites
Windows Operating System

PowerShell 5.1 or higher: (This is standard on Windows 10 and 11).

Administrator Privileges: The script must be run as an Administrator to change system audio settings.

AudioDeviceCmdlets PowerShell Module: The script relies on this module by Frank Maruth (frgn). It will attempt to install it automatically from the PowerShell Gallery if it's not found. Internet access is required for the first-time module installation.

(Optional) Custom Sound Files: If using custom sounds, they should ideally be in .wav format.

Setup
Download the Script:

Save the script as DualAudioDefaults.ps1 (or your preferred name) to a convenient location on your computer (e.g., C:\Users\YourUser\Documents\PowerShell_Scripts\).

(Optional) Prepare Custom Sound Files:

If you want to use custom sound files:

Create a folder named Sound in the same directory where you saved DualAudioDefaults.ps1.

Place your .wav files (e.g., Mallet - S.wav, Mallet - E.wav) into this Sound folder.

Alternatively, you can use full paths to sound files located anywhere on your system, or use built-in system sound names.

Configure the Script:

Open DualAudioDefaults.ps1 in a text editor (like Notepad, VS Code, or PowerShell ISE).

Device Configuration (for Toggle):

Locate the section --- Configuration for Toggle ---.

Modify the $Device1_Identifier and $Device2_Identifier variables with the exact names or IDs of the two audio devices you want to toggle between. You can find these by running the script with the -ListDevices parameter first.

# Example:
$Device1_Identifier = "Speakers (Realtek High Definition Audio)" 
$Device2_Identifier = "Headphones (My USB Headset)" 
# Or using IDs:
# $Device1_Identifier = "{0.0.0.00000000}.{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"

Sound Configuration:

Locate the section --- Configuration for Sounds ---.

Modify the $SoundIdentifier_BeforeChange, $SoundIdentifier_AfterSuccess, and $SoundIdentifier_OnError variables.

For custom sounds in the Sound subdirectory (recommended):

$SoundIdentifier_BeforeChange = Join-Path -Path $PSScriptRoot -ChildPath "Sound\Mallet - S.wav"
$SoundIdentifier_AfterSuccess = Join-Path -Path $PSScriptRoot -ChildPath "Sound\Mallet - E.wav"

For full paths to custom sounds:

$SoundIdentifier_BeforeChange = "C:\Path\To\MySounds\start_sound.wav"

For built-in system sounds:

$SoundIdentifier_OnError = "Hand" 

(Valid system sound names: "Asterisk", "Beep", "Exclamation", "Hand", "Question")

To disable a sound, set its variable to $null or an empty string "".

Save the script file.

How to Use
PowerShell Execution Policy
If you haven't run PowerShell scripts before, you might need to set your execution policy. Run PowerShell as Administrator and execute:

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Running the Script from PowerShell
Open PowerShell as Administrator.

Navigate to the directory where you saved the script:

cd C:\Path\To\Your\Script\Directory

Execute the script with one of the following parameters:

List available audio devices:

.\DualAudioDefaults.ps1 -ListDevices

(Note the Name or ID for configuring the toggle or setting a specific device).

Set a specific device as default for both playback and communication:
Replace "Your Device Name or ID" with the actual identifier.

.\DualAudioDefaults.ps1 -DeviceNameOrID "Your Device Name or ID"

(Example: .\DualAudioDefaults.ps1 -DeviceNameOrID "Speakers (Realtek High Definition Audio)")

Toggle between your two configured devices:

.\DualAudioDefaults.ps1 -Toggle

PowerToys Integration (Recommended for Quick Toggling)
You can assign a keyboard shortcut to the toggle functionality using PowerToys Keyboard Manager. This allows you to switch your audio setup without opening PowerShell manually.

Open PowerToys Settings:

Find the PowerToys icon in your system tray (usually near the clock, may be hidden under an arrow).

Right-click the icon and select "Settings."

Navigate to Keyboard Manager:

In the PowerToys Settings window, select "Keyboard Manager" from the sidebar menu.

Ensure the "Enable Keyboard Manager" toggle at the top is switched ON.

Access Shortcut Remapping:

Under the "Shortcuts" section, click the button labeled "Remap a shortcut."

Add a New Remapping Rule:

In the "Remap shortcuts" window, click the "+ Add shortcut remapping" button (or a simple "+" icon). A new row will appear for you to define your shortcut.

Configure the Shortcut and Action:

"Shortcut" column (or "Select:"):

Click the "Type" button (or the pencil icon, or directly into the "Shortcut" box).

Press the physical keys on your keyboard that you want to use as your shortcut (e.g., Ctrl + Alt + T, or Win + Shift + A). Choose a combination that you don't use for other applications.

Click "OK" or ensure the keys are registered in the box.

"Action" column (or "To:"):

Click the dropdown menu.

Select Run Program. This will reveal more fields to configure.

"App:" field:

Enter the full path to the PowerShell executable:
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

"Args:" field (Arguments for program):

Enter the following, carefully replacing the example path with the actual full path to where you saved your script:
-NoProfile -ExecutionPolicy Bypass -File "C:\Path\To\Your\DualAudioDefaults.ps1" -Toggle

Example if your script is in C:\Users\YourUserName\Scripts\DualAudioDefaults.ps1:
-NoProfile -ExecutionPolicy Bypass -File "C:\Users\YourUserName\Scripts\DualAudioDefaults.ps1" -Toggle

"Start in:" field (Start in directory):

This is usually optional if you've provided the full path in "Args:". You can leave it blank or set it to the directory containing your script (e.g., C:\Users\YourUserName\Scripts\).

"Elevation:" field:

Click the dropdown and select Elevated. This is crucial for the script to have permission to change system settings.

"If running:" field:

The default option (e.g., "Start new instance" or "Show window") is generally fine.

"Visibility:" field:

Select Hidden from the dropdown. This is recommended to prevent the PowerShell window from briefly flashing on screen when the shortcut is used. If Hidden causes any issues, Normal can be used, but a window will appear momentarily.

Save the Remapping:

Click the "OK" button at the top of the "Remap shortcuts" window to apply and save your new shortcut configuration.

PowerToys will apply the changes.

Test Your Shortcut:

Press the keyboard shortcut you defined.

You should see a User Account Control (UAC) prompt asking for permission to allow PowerShell to make changes. You must click "Yes" for the script to run.

Your audio devices should then toggle according to your script's configuration, and you should hear your configured sound notifications.

Troubleshooting
"Running scripts is disabled on this system": You need to set your PowerShell Execution Policy. See the "PowerShell Execution Policy" section above.

AudioDeviceCmdlets module installation fails: Ensure you have an internet connection. If automatic installation fails, try running Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser -Force manually in an Administrator PowerShell window.

Sounds not playing:

For custom sounds, ensure the file path in the script configuration is correct and the file is a valid .wav file.

Ensure your system volume is not muted.

"Access Denied" or settings not changing: Make sure you are running the PowerShell script (or PowerToys is launching it) with Administrator / Elevated privileges. The UAC prompt must be accepted.

"Parameter set cannot be resolved" or "AmbiguousParameterSet" when running Get-AudioDevice directly: This cmdlet requires specific parameters like -List or -ID. The script handles this internally.

Acknowledgements
This script utilizes the AudioDeviceCmdlets PowerShell module by Frank Maruth (frgn).

This script was developed with the assistance of AI.
