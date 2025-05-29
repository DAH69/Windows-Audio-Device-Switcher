#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Sets a specified audio playback device as both the Default Device and Default Communication Device,
    lists available audio playback devices, or toggles between two predefined audio devices.
    Plays user-configurable custom sound files (.wav recommended, plays synchronously) or system sounds for feedback.
    Looks for custom sound files in a 'Sound' subdirectory by default if relative paths are configured.

.DESCRIPTION
    This script uses the 'AudioDeviceCmdlets' module (by frgn) to manage audio devices.
    If the module is not installed, it will attempt to install it from the PowerShell Gallery.

    You need to run this script as an Administrator.

    For Toggle functionality, edit the $Device1_Identifier and $Device2_Identifier variables.
    For Sound configuration, edit the $SoundIdentifier_BeforeChange, $SoundIdentifier_AfterSuccess, 
    and $SoundIdentifier_OnError variables. These can be:
    1. Full paths to .wav files.
    2. Relative paths to .wav files (e.g., "Sound\my_sound.wav") which will be resolved from the script's location.
    3. One of the system sound names: "Asterisk", "Beep", "Exclamation", "Hand", "Question".

.PARAMETER DeviceNameOrID
    The name or ID of the audio playback device you want to set as default for both roles.
    Use the -ListDevices switch first to find the correct name or ID. Names are case-sensitive.

.PARAMETER ListDevices
    If specified, the script will list all available audio playback devices and their details.

.PARAMETER Toggle
    If specified, the script will toggle the default playback and communication device
    between two predefined devices ($Device1_Identifier and $Device2_Identifier in the script).

.EXAMPLE
    .\DualAudioDefaults.ps1 -ListDevices

.EXAMPLE
    .\DualAudioDefaults.ps1 -DeviceNameOrID "Speakers (Realtek High Definition Audio)"

.EXAMPLE
    .\DualAudioDefaults.ps1 -Toggle
    # (Ensure you've edited device and sound configurations in the script)

.NOTES
    Author: Gemini
    Date: 2025-05-29
    Requires: AudioDeviceCmdlets module from PowerShell Gallery.
              Administrator privileges.
              Custom sound files should ideally be in .wav format.
    Version: 2.1 (Sound paths default to 'Sound' subdirectory relative to script)
#>

[CmdletBinding(DefaultParameterSetName = "SetDevice")]
param (
    [Parameter(Mandatory = $false, ParameterSetName = "SetDevice", HelpMessage = "Name or ID of the audio device to set.")]
    [string]$DeviceNameOrID,

    [Parameter(Mandatory = $true, ParameterSetName = "List", HelpMessage = "List available playback audio devices.")]
    [switch]$ListDevices,

    [Parameter(Mandatory = $true, ParameterSetName = "ToggleDevices", HelpMessage = "Toggle between two predefined audio devices.")]
    [switch]$Toggle
)

# --- Configuration for Toggle ---
# !!! EDIT THESE VALUES TO MATCH YOUR DEVICE NAMES OR IDs !!!
$Device1_Identifier = "Speakers (Realtek High Definition Audio)" # <-- REPLACE WITH YOUR FIRST DEVICE NAME OR ID
$Device2_Identifier = "Speakers (AB13X USB Audio)" # <-- REPLACE WITH YOUR SECOND DEVICE NAME OR ID
# !!! --------------------------------------------------- !!!

# --- Configuration for Sounds ---
# Provide:
# 1. Full paths to your .wav sound files (e.g., "C:\MySounds\start.wav")
# 2. Relative paths to .wav files from the script's directory (e.g., "Sound\start.wav")
# 3. A system sound name: "Asterisk", "Beep", "Exclamation", "Hand", "Question"
# Set to $null or an empty string to disable a specific sound.

# $PSScriptRoot is the directory where the script is located.
# Using Join-Path to correctly build paths to a 'Sound' subdirectory.
$SoundIdentifier_BeforeChange = Join-Path -Path $PSScriptRoot -ChildPath "Sound\Mallet - S.wav"
$SoundIdentifier_AfterSuccess = Join-Path -Path $PSScriptRoot -ChildPath "Sound\Mallet - E.wav"
$SoundIdentifier_OnError      = "Hand" # Using a system sound for errors, or change to a relative/absolute file path.
# Example for error sound file: $SoundIdentifier_OnError = Join-Path -Path $PSScriptRoot -ChildPath "Sound\error.wav"
# !!! --------------------------------------------------- !!!


# --- Function to Play Configured Sound (File Path or System Sound Name) ---
function Play-ConfiguredSound {
    param (
        [string]$SoundIdentifier 
    )
    if (-not [string]::IsNullOrWhiteSpace($SoundIdentifier)) {
        $knownSystemSounds = @{
            "asterisk"    = { [System.Media.SystemSounds]::Asterisk.Play() }
            "beep"        = { [System.Media.SystemSounds]::Beep.Play() }
            "exclamation" = { [System.Media.SystemSounds]::Exclamation.Play() }
            "hand"        = { [System.Media.SystemSounds]::Hand.Play() }
            "question"    = { [System.Media.SystemSounds]::Question.Play() }
        }

        $lowerSoundIdentifier = $SoundIdentifier.ToLowerInvariant()

        if ($knownSystemSounds.ContainsKey($lowerSoundIdentifier)) {
            try {
                # System sounds play synchronously by default
                Invoke-Command -ScriptBlock $knownSystemSounds[$lowerSoundIdentifier]
                Write-Verbose "Played system sound: $SoundIdentifier"
            }
            catch {
                Write-Warning "Could not play system sound '$SoundIdentifier'. Error: $($_.Exception.Message)"
            }
        }
        else { # Assume it's a file path
            $resolvedPath = $SoundIdentifier
            # If it's not an absolute path, assume it's relative to the script root (this logic is now handled by Join-Path in config)
            # However, keeping Test-Path to ensure the constructed path (absolute or relative resolved by Join-Path) is valid.
            if (-not (Test-Path -Path $resolvedPath -PathType Leaf -IsValid)) {
                 # Check if it might be an intentionally relative path not using $PSScriptRoot directly in the variable
                 # This is mostly for robustness if user types "Sound\file.wav" directly into var without Join-Path
                if (-not [System.IO.Path]::IsPathRooted($resolvedPath)) {
                    $resolvedPath = Join-Path -Path $PSScriptRoot -ChildPath $SoundIdentifier
                }
            }

            if (Test-Path -Path $resolvedPath -PathType Leaf) {
                try {
                    $player = New-Object System.Media.SoundPlayer($resolvedPath)
                    $player.PlaySync() 
                    Write-Verbose "Played sound file synchronously: $resolvedPath"
                }
                catch {
                    Write-Warning "Could not play sound file '$resolvedPath'. Error: $($_.Exception.Message)"
                    Write-Warning "Ensure the file is a valid .wav format and the path is correct."
                }
            }
            else {
                Write-Warning "Sound identifier '$SoundIdentifier' (resolved to '$resolvedPath') is not a recognized system sound and the file was not found. Please check the configuration."
            }
        }
    }
}

# --- Function to Check and Install Module ---
function Ensure-AudioDeviceCmdletsModule {
    Write-Verbose "Checking if AudioDeviceCmdlets module is installed."
    $module = Get-Module -Name AudioDeviceCmdlets -ListAvailable
    if (-not $module) {
        Write-Host "AudioDeviceCmdlets module not found. Attempting to install..."
        try {
            Install-Module -Name AudioDeviceCmdlets -Repository PSGallery -Force -Scope CurrentUser -Confirm:$false -SkipPublisherCheck
            Write-Host "AudioDeviceCmdlets module installed successfully. Please re-run the script for changes to fully take effect if issues persist."
            Import-Module AudioDeviceCmdlets -ErrorAction Stop
            Write-Host "Module imported for current session."
        }
        catch {
            Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_OnError
            Write-Error "Failed to install AudioDeviceCmdlets module. Error: $($_.Exception.Message)"
            Write-Error "Please try installing it manually: Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser"
            exit 1
        }
    }
    else {
        Write-Verbose "AudioDeviceCmdlets module is already installed."
        if (-not (Get-Module -Name AudioDeviceCmdlets)) {
            Import-Module AudioDeviceCmdlets -ErrorAction SilentlyContinue
            Write-Verbose "AudioDeviceCmdlets module imported for current session."
        }
    }
}

# --- Function to List Playback Devices ---
function Show-PlaybackAudioDevices {
    Write-Host "Available Playback Audio Devices:" -ForegroundColor Yellow
    try {
        Get-AudioDevice -List | Where-Object {$_.Type -eq 'Playback'} | Format-Table -AutoSize -Wrap `
            @{Label="Index"; Expression={$_.Index}}, `
            @{Label="Name"; Expression={$_.Name}}, `
            @{Label="ID"; Expression={$_.ID}}, `
            @{Label="Default"; Expression={$_.Default}}, `
            @{Label="DefaultComm"; Expression={$_.DefaultCommunication}}
        Write-Host "`nNote: 'Default' indicates the Default Playback Device."
        Write-Host "'DefaultComm' indicates the Default Communication Device."
    }
    catch {
        Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_OnError
        Write-Error "Failed to list audio devices. Error: $($_.Exception.Message)"
        Write-Error "Ensure the AudioDeviceCmdlets module is correctly installed and imported."
    }
}

# --- Function to Resolve Device Identifier to Device Object ---
function Resolve-DeviceIdentifier {
    param(
        [string]$Identifier
    )
    $resolvedDevice = $null
    if ($Identifier -like "*{*}*") { 
        $resolvedDevice = Get-AudioDevice -ID $Identifier -ErrorAction SilentlyContinue
    }
    if (-not $resolvedDevice) {
        $resolvedDevice = (Get-AudioDevice -List | Where-Object { $_.Type -eq 'Playback' -and $_.Name -eq $Identifier }) | Select-Object -First 1
    }
    if ($resolvedDevice -and $resolvedDevice.Type -ne 'Playback') {
        Write-Warning "Device '$($Identifier)' resolved to a non-playback device: $($resolvedDevice.Type). Ignoring."
        return $null
    }
    return $resolvedDevice
}

# --- Function to Set Default Audio Device for Both Roles ---
function Set-DualDefaultAudioDevice {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetDeviceNameOrID 
    )

    Write-Host "Attempting to set '$TargetDeviceNameOrID' as default for playback and communication..."
    Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_BeforeChange
    
    $deviceToSet = Resolve-DeviceIdentifier -Identifier $TargetDeviceNameOrID

    if ($deviceToSet) {
        Write-Host "Found playback device: $($deviceToSet.Name) (ID: $($deviceToSet.ID))"
        try {
            Set-AudioDevice -ID $deviceToSet.ID -Default -ErrorAction Stop
            Write-Host "Successfully set '$($deviceToSet.Name)' as Default Playback Device."

            Set-AudioDevice -ID $deviceToSet.ID -Communication -ErrorAction Stop
            Write-Host "Successfully set '$($deviceToSet.Name)' as Default Communication Playback Device."

            Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_AfterSuccess
            Write-Host "Operation completed." -ForegroundColor Green
        }
        catch {
            Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_OnError
            Write-Error "Failed to set audio device '$($deviceToSet.Name)'. Error: $($_.Exception.Message)"
        }
    }
    else {
        Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_OnError
        Write-Error "Could not find a unique playback audio device matching: '$TargetDeviceNameOrID'"
        Write-Host "Please use the -ListDevices switch to see available devices and verify the Name (case-insensitive by default) or preferably use the unique ID."
    }
}

# --- Main Script Logic ---
Ensure-AudioDeviceCmdletsModule

if ($Toggle) {
    Write-Host "Attempting to toggle audio devices..." -ForegroundColor Cyan
    Write-Host "Configured Device 1: '$Device1_Identifier'"
    Write-Host "Configured Device 2: '$Device2_Identifier'"

    $Device1 = Resolve-DeviceIdentifier -Identifier $Device1_Identifier
    $Device2 = Resolve-DeviceIdentifier -Identifier $Device2_Identifier

    if (-not $Device1) {
        Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_OnError
        Write-Error "Toggle failed: Could not find or resolve Device1 configured as '$Device1_Identifier'. Please check the configuration and ensure it's a playback device."
        exit 1
    }
    if (-not $Device2) {
        Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_OnError
        Write-Error "Toggle failed: Could not find or resolve Device2 configured as '$Device2_Identifier'. Please check the configuration and ensure it's a playback device."
        exit 1
    }
    if ($Device1.ID -eq $Device2.ID) {
        Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_OnError
        Write-Error "Toggle failed: Device1 and Device2 are configured to be the same device ('$($Device1.Name)'). Please configure two different devices at the top of the script."
        exit 1
    }

    $currentDefaultPlayback = Get-AudioDevice -Playback -ErrorAction SilentlyContinue
    if (-not $currentDefaultPlayback) {
        Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_OnError
        Write-Error "Toggle failed: Could not determine the current default playback device."
        exit 1
    }
    Write-Host "Current default playback device: $($currentDefaultPlayback.Name) (ID: $($currentDefaultPlayback.ID))"
    Write-Host "Device1 to toggle: $($Device1.Name) (ID: $($Device1.ID))"
    Write-Host "Device2 to toggle: $($Device2.Name) (ID: $($Device2.ID))"

    $targetDeviceIdentifierForSet = $null

    if ($currentDefaultPlayback.ID -eq $Device1.ID) {
        Write-Host "Current default is Device1. Switching to Device2: $($Device2.Name)"
        $targetDeviceIdentifierForSet = $Device2_Identifier 
    }
    elseif ($currentDefaultPlayback.ID -eq $Device2.ID) {
        Write-Host "Current default is Device2. Switching to Device1: $($Device1.Name)"
        $targetDeviceIdentifierForSet = $Device1_Identifier 
    }
    else {
        Write-Host "Current default ('$($currentDefaultPlayback.Name)') is neither configured Device1 nor Device2. Switching to Device1 ('$($Device1.Name)') by default."
        $targetDeviceIdentifierForSet = $Device1_Identifier 
    }
    
    if ($targetDeviceIdentifierForSet) {
        Set-DualDefaultAudioDevice -TargetDeviceNameOrID $targetDeviceIdentifierForSet
    } else {
        Play-ConfiguredSound -SoundIdentifier $SoundIdentifier_OnError
        Write-Error "Toggle logic failed to determine a target device. This should not happen if Device1 is configured correctly."
    }
}
elseif ($ListDevices) {
    Show-PlaybackAudioDevices
}
elseif ($DeviceNameOrID) {
    Set-DualDefaultAudioDevice -TargetDeviceNameOrID $DeviceNameOrID
}
else {
    Write-Host "No valid action specified. Use -ListDevices, -Toggle, or -DeviceNameOrID."
    Get-Help $MyInvocation.MyCommand.Path -Full
}

Write-Verbose "Script finished."
