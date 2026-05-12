<#
	.SYNOPSIS
	Download the latest Sophia Script version from the last commit available, depending on which Windows or PowerShell versions are used to

	.SYNOPSIS
	For example, if you start script on Windows 11 via PowerShell 5.1 you will start downloading Sophia Script for Windows 11 PowerShell 5.1

	.EXAMPLE
	iwr sl.sophia.team -useb | iex
#>

Clear-Host
$Error.Clear()

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($Host.Version.Major -eq 5)
{
	# Progress bar can significantly impact cmdlet performance
	# https://github.com/PowerShell/PowerShell/issues/2138
	$Script:ProgressPreference = "SilentlyContinue"
}

# https://github.com/PowerShell/PowerShell/issues/21070
$Script:CompilerParameters                  = [System.CodeDom.Compiler.CompilerParameters]::new("System.dll")
$Script:CompilerParameters.TempFiles        = [System.CodeDom.Compiler.TempFileCollection]::new($env:TEMP, $false)
$Script:CompilerParameters.GenerateInMemory = $true

switch ((Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber)
{
	"17763"
	{
		# Windows 10 LTSC 2019
		if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName) -match "LTSC 2019")
		{
			$Version = "Sophia_Script_for_Windows_10_LTSC_2019"
		}
		else
		{
			Write-Verbose -Message "Windows version is not supported. Update your Windows and try again." -Verbose

			# Receive updates for other Microsoft products when you update Windows
			(New-Object -ComObject Microsoft.Update.ServiceManager).AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "")

			# Check for updates
			& "$env:SystemRoot\System32\UsoClient.exe" StartInteractiveScan

			# Open the "Windows Update" page
			Start-Process -FilePath "ms-settings:windowsupdate"

			Write-Verbose -Message "https://t.me/sophia_chat" -Verbose
			Write-Verbose -Message "https://discord.gg/sSryhaEv79" -Verbose

			pause
			exit
		}
	}
	"19044"
	{
		# Windows 10 LTSC 2021
		if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName) -match "LTSC 2021")
		{
			$Version = "Sophia_Script_for_Windows_10_LTSC_2021"
		}
		else
		{
			Write-Verbose -Message "Your Windows version is not supported. Update your Windows and try again." -Verbose

			# Receive updates for other Microsoft products when you update Windows
			(New-Object -ComObject Microsoft.Update.ServiceManager).AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "")

			# Check for updates
			& "$env:SystemRoot\System32\UsoClient.exe" StartInteractiveScan

			# Open the "Windows Update" page
			Start-Process -FilePath "ms-settings:windowsupdate"

			Write-Verbose -Message "https://t.me/sophia_chat" -Verbose
			Write-Verbose -Message "https://discord.gg/sSryhaEv79" -Verbose

			pause
			exit
		}
	}
	"19045"
	{
		if ($Host.Version.Major -eq 5)
		{
			$Version = "Sophia_Script_for_Windows_10"
		}
		else
		{
			$Version = "Sophia_Script_for_Windows_10_PowerShell_7"
		}
	}
	{$_ -gt 19045}
	{
		# Windows 11 LTSC 2024
		if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName) -match "LTSC 2024")
		{
			if ($PSVersionTable.PSVersion.Major -lt 6)
			{
				$Version = "Sophia_Script_for_Windows_11_LTSC_2024"
			}
			else
			{
				$Version = "Sophia_Script_for_Windows_11_LTSC_2024_PowerShell_7"
			}
		}
		else
		{
			if ($Host.Version.Major -eq 5)
			{
				if ((Get-CimInstance -ClassName CIM_Processor).Caption -match "ARM")
				{
					$Version = "Sophia_Script_for_Windows_11_ARM"
				}
				else
				{
					$Version = "Sophia_Script_for_Windows_11"
				}
			}
			else
			{
				if ((Get-CimInstance -ClassName CIM_Processor).Caption -match "ARM")
				{
					$Version = "Sophia_Script_for_Windows_11_ARM_PowerShell_7"
				}
				else
				{
					$Version = "Sophia_Script_for_Windows_11_PowerShell_7"
				}
			}
		}
	}
}

try {
	# 1. Download specific files (Hash Table)
	$myHash = @{
		"https://github.com/farag2/Sophia-Script-for-Windows/raw/main/src/$Version/Localizations/en-US/Sophia.psd1" = 'Localizations\en-US\Sophia.psd1';
		"https://github.com/farag2/Sophia-Script-for-Windows/raw/main/src/$Version/Localizations/ru-RU/Sophia.psd1" = 'Localizations\ru-RU\Sophia.psd1';
		"https://github.com/farag2/Sophia-Script-for-Windows/raw/main/src/$Version/Manifest/SophiaScript.psd1"      = 'Manifest\SophiaScript.psd1';
		"https://github.com/farag2/Sophia-Script-for-Windows/raw/main/src/$Version/Import-TabCompletion.ps1"        = 'Import-TabCompletion.ps1';
	}
	
	ForEach ($file in $myHash.GetEnumerator()) {
		 # 1. Абсолютный путь назначения (в папке скрипта)
        $destinationPath = Join-Path -Path $PSScriptRoot\$Version -ChildPath $file.Value
		Invoke-WebRequest -Uri $file.Key -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop
	}

	# Set path to Compare tool
	$compare = "$PSScriptRoot\..\Programm\Beyond Compare\BCompare.exe"

	ForEach ($file in Get-ChildItem -Path "$PSScriptRoot\$Version\Module\Private") {
    	& $compare $file.FullName https://github.com/farag2/Sophia-Script-for-Windows/raw/main/src/$Version/Module/Private/$($file.Name)
	}
	& $compare $PSScriptRoot\$Version\Module\Sophia.psm1 https://github.com/farag2/Sophia-Script-for-Windows/raw/main/src/$Version/Module/Sophia.psm1 
	& $compare $PSScriptRoot\$Version\Sophia.ps1 https://github.com/farag2/Sophia-Script-for-Windows/raw/main/src/$Version/Sophia.ps1
}
catch {
    Write-Verbose "Download failed: $_"

	# Try to display available AVs
	try
	{
		Get-CimInstance -ClassName AntiVirusProduct -Namespace root/SecurityCenter2
	}
	catch {}

	# Check for updates
	& "$env:SystemRoot\System32\UsoClient.exe" StartInteractiveScan

	# Open t"Windows Update" page
	Start-Process -FilePath "ms-settings:windowsupdate"

	pause
	exit
}

$binDir = "$PSScriptRoot\$Version\Binaries"
if (Test-Path "$binDir\LGPO.exe") 
{
	Write-Verbose "Skip LGPO download: found LGPO.exe"
}
else {
	New-Item -Path "$PSScriptRoot\$Version\Binaries" -ItemType Directory -ErrorAction SilentlyContinue

	# Download LGPO
	# https://techcommunity.microsoft.com/t5/microsoft-security-baselines/lgpo-exe-local-group-policy-object-utility-v1-0/ba-p/701045
	$Parameters = @{
		Uri             = "https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip"
		OutFile         = "$env:temp\LGPO.zip"
		UseBasicParsing = $true
		Verbose         = $true
	}
Invoke-WebRequest @Parameters
& "$env:SystemRoot\System32\tar.exe" -xvf "$env:temp\LGPO.zip" -C "$PSScriptRoot\$Version\Binaries" --strip-components=1 "LGPO_30/LGPO.exe"
}

if ($Version -match "PowerShell_7") {
	$sdkDll = Join-Path $binDir "Microsoft.Windows.SDK.NET.dll"
	$winRtDll = Join-Path $binDir "WinRT.Runtime.dll"
	if (-not (Test-Path $sdkDll) -or -not (Test-Path $winRtDll)) {
		# Download Microsoft.Windows.SDK.NET.dll & WinRT.Runtime.dll
		# https://www.nuget.org/packages/Microsoft.Windows.SDK.NET.Ref
		$Parameters = @{
			Uri             = "https://www.nuget.org/api/v2/package/Microsoft.Windows.SDK.NET.Ref"
			OutFile         = "$env:temp\microsoft.windows.sdk.net.ref.zip"
			UseBasicParsing = $true
		}
		Invoke-RestMethod @Parameters

		# Extract Microsoft.Windows.SDK.NET.dll & WinRT.Runtime.dll from archive
		& "$env:SystemRoot\System32\tar.exe" -xvf "$env:temp\microsoft.windows.sdk.net.ref.zip" -C "$PSScriptRoot\$Version\Binaries" --strip-components=2 "lib/net8.0/WinRT.Runtime.dll" "lib/net8.0/Microsoft.Windows.SDK.NET.dll"
	}
}

$Path = @(
	"$env:temp\LGPO.zip",
	"$env:temp\microsoft.windows.sdk.net.ref.zip"
)
Remove-Item -Path $Path -Recurse -Force -ErrorAction Ignore

$script = Join-Path $PSScriptRoot "$Version\Sophia.ps1"
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Script needs to be run as Administrator. Attempting to relaunch."


    $powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { "$powershellCmd" }

    if ($processCmd -eq "wt.exe") {
        Start-Process $processCmd -ArgumentList "$powershellCmd -ExecutionPolicy Bypass -NoProfile -File $script" -Verb RunAs
    } else {
        Start-Process $processCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$script`"" -Verb RunAs
    }

    break
}
else{ 
	& "$script"
}