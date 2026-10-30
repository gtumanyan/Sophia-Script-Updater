<#
	.SYNOPSIS
	Download the latest Sophia Script version from the last commit available, depending on which Windows or PowerShell versions are used to

	.DESCRIPTION
	For example, if you start script on Windows 11 via PowerShell 5.1 you will start downloading Sophia Script for Windows 11 PowerShell 5.1

	.EXAMPLE
	iwr sl.sophia.team -useb | iex
#>

Clear-Host
$Error.Clear()

if ($Host.Version.Major -eq 5) {
	# Progress bar can significantly impact cmdlet performance
	# https://github.com/PowerShell/PowerShell/issues/2138
	$Script:ProgressPreference = "SilentlyContinue"

	[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

	# https://github.com/PowerShell/PowerShell/issues/21070
	$Script:CompilerParameters = [System.CodeDom.Compiler.CompilerParameters]::new("System.dll")
	$Script:CompilerParameters.TempFiles = [System.CodeDom.Compiler.TempFileCollection]::new($env:TEMP, $false)
	$Script:CompilerParameters.GenerateInMemory = $true
}

$ProductName = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName
$Version = $null

switch ([int](Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_OperatingSystem).BuildNumber) {
	17763 {
		# Windows 10 LTSC 2019
		if ($ProductName -match "LTSC 2019") {
			$Version = "Sophia_Script_for_Windows_10_LTSC_2019"
		}
	}
	19044 {
		# Windows 10 LTSC 2021
		if ($ProductName -match "LTSC 2021") {
			$Version = "Sophia_Script_for_Windows_10_LTSC_2021"
		}
	}
	19045 {
		# Windows 10
		if ($PSVersionTable.PSVersion.Major -eq 5) {
			$Version = "Sophia_Script_for_Windows_10"
		}
		else {
			$Version = "Sophia_Script_for_Windows_10_PowerShell_7"
		}
	}
	{ $_ -gt 19045 } {
		if ($ProductName -match "LTSC 2024") {
			# Windows 11 LTSC 2024
			if ($PSVersionTable.PSVersion.Major -eq 5) {
				$Version = "Sophia_Script_for_Windows_11_LTSC_2024"
			}
			else {
				$Version = "Sophia_Script_for_Windows_11_LTSC_2024_PowerShell_7"
			}
		}
		elseif ((Get-CimInstance -Namespace root/CIMV2 -ClassName CIM_Processor).Architecture -eq 12) {
			# Windows 11 Arm
			if ($PSVersionTable.PSVersion.Major -eq 5) {
				$Version = "Sophia_Script_for_Windows_11_Arm"
			}
			else {
				$Version = "Sophia_Script_for_Windows_11_Arm_PowerShell_7"
			}
		}
		else {
			# Windows 11
			if ($PSVersionTable.PSVersion.Major -eq 5) {
				$Version = "Sophia_Script_for_Windows_11"
			}
			else {
				$Version = "Sophia_Script_for_Windows_11_PowerShell_7"
			}
		}
	}
}

if (-not $Version) {
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

# New-Item -Path "$env:SystemDrive\Sophia_Script_Temp" -ItemType Directory -Force

try {
	# Download specific files (Hash Table)
	$myHash = @{
		"https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/refs/heads/main/src/$Version/Module/Localizations/en-US/Sophia.psd1" = 'Module\Localizations\en-US\Sophia.psd1';
		"https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/refs/heads/main/src/$Version/Module/Localizations/ru-RU/Sophia.psd1" = 'Module\Localizations\ru-RU\Sophia.psd1';
		"https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/refs/heads/main/src/$Version/Module/Manifest/SophiaScript.psd1"      = 'Module\Manifest\SophiaScript.psd1';
		"https://raw.githubusercontent.com/farag2/Sophia-Script-for-Windows/refs/heads/main/src/$Version/Import-TabCompletion.ps1"               = 'Import-TabCompletion.ps1';
	}
	
	ForEach ($file in $myHash.GetEnumerator()) {
		# Абсолютный путь назначения (в папке скрипта)
		$destinationPath = Join-Path -Path $PSScriptRoot\$Version -ChildPath $file.Value
		Invoke-WebRequest $file.Key -OutFile $destinationPath -Verbose
	}

	$binDir = "$PSScriptRoot\$Version\Module\Binaries"
$tarExe = Join-Path -Path $env:SystemRoot -ChildPath "System32\tar.exe"

	# LGPO: проверка → скачивание → распаковка
	$lgpoExe = Join-Path -Path $binDir -ChildPath "LGPO.exe"

	if (-not (Test-Path -LiteralPath $lgpoExe -PathType Leaf)) {
		$lgpoZip = Join-Path -Path $env:TEMP -ChildPath "LGPO.zip"

		Invoke-WebRequest `
			-Uri "https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip" `
			-OutFile $lgpoZip `
			-UseBasicParsing `
			-ErrorAction Stop `
			-Verbose

		& $tarExe -xvf $lgpoZip -C $binDir `
			--strip-components=1 "LGPO_30/LGPO.exe"

		if ($LASTEXITCODE -ne 0 -or
			-not (Test-Path -LiteralPath $lgpoExe -PathType Leaf)) {
			throw "Не удалось извлечь LGPO.exe из '$lgpoZip'."
		}

		Remove-Item -LiteralPath $lgpoZip -Force -ErrorAction SilentlyContinue
	}
	else {
		Write-Verbose "LGPO.exe найден — загрузка и распаковка пропущены." -Verbose
	}

	# SDK DLL проверяются независимо от наличия LGPO.exe
	if ($Version -match "PowerShell_7") {
		$sdkDll = Join-Path -Path $binDir -ChildPath "Microsoft.Windows.SDK.NET.dll"
		$winRtDll = Join-Path -Path $binDir -ChildPath "WinRT.Runtime.dll"

		if (-not (Test-Path -LiteralPath $sdkDll -PathType Leaf) -or
			-not (Test-Path -LiteralPath $winRtDll -PathType Leaf)) {

			$sdkZip = Join-Path -Path $env:TEMP -ChildPath "microsoft.windows.sdk.net.ref.zip"

			Invoke-WebRequest `
				-Uri "https://www.nuget.org/api/v2/package/Microsoft.Windows.SDK.NET.Ref" `
				-OutFile $sdkZip `
				-UseBasicParsing `
				-ErrorAction Stop `
				-Verbose

			& $tarExe -xvf $sdkZip -C $binDir `
				--strip-components=2 `
				"lib/net9.0/WinRT.Runtime.dll" `
				"lib/net9.0/Microsoft.Windows.SDK.NET.dll"

			if ($LASTEXITCODE -ne 0 -or
				-not (Test-Path -LiteralPath $sdkDll -PathType Leaf) -or
				-not (Test-Path -LiteralPath $winRtDll -PathType Leaf)) {
				throw "Не удалось извлечь SDK DLL из '$sdkZip'."
			}

			Remove-Item -LiteralPath $sdkZip -Force -ErrorAction SilentlyContinue
		}
		else {
			Write-Verbose "SDK DLL найдены — загрузка и распаковка пропущены." -Verbose
		}
	}
}
catch {
	Write-Error -Message $_
	Write-Information -MessageData "" -InformationAction Continue

	$InterfaceIndex = (Find-NetRoute -RemoteIPAddress "1.1.1.1" | Select-Object -First 1).InterfaceIndex
	$DNS = (Get-NetAdapter -InterfaceIndex $InterfaceIndex | Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses

	Write-Warning -Message "You're using $(if ($DNS.Count -gt 1) {$DNS -join ', '} else {$DNS}) DNS records"
	pause
	exit
}

# Set path to Compare tool
$compare = "$PSScriptRoot\..\..\Programm\Beyond Compare\BComp"
$repo = "farag2/Sophia-Script-for-Windows"
$branch = "main"
$localRoot = Join-Path -Path $PSScriptRoot -ChildPath $Version

function Get-GitBlobHash {
	param ([byte[]]$Bytes)

	$header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
	$data = [byte[]]::new($header.Length + $Bytes.Length)
	[Buffer]::BlockCopy($header, 0, $data, 0, $header.Length)
	[Buffer]::BlockCopy($Bytes, 0, $data, $header.Length, $Bytes.Length)

	$sha1 = [Security.Cryptography.SHA1]::Create()
	try { -join ($sha1.ComputeHash($data) | ForEach-Object { $_.ToString("x2") }) }
	finally { $sha1.Dispose() }
}

function Get-LocalGitHashes {
	# Хэш файла как есть + хэш с CRLF→LF (на случай разных окончаний строк)
	param ([string]$Path)

	$bytes = [IO.File]::ReadAllBytes($Path)
	$lf = [Collections.Generic.List[byte]]::new($bytes.Length)
	for ($i = 0; $i -lt $bytes.Length; $i++) {
		if ($bytes[$i] -eq 13 -and $i + 1 -lt $bytes.Length -and $bytes[$i + 1] -eq 10) { continue }
		$lf.Add($bytes[$i])
	}

	@((Get-GitBlobHash $bytes), (Get-GitBlobHash $lf.ToArray())) | Select-Object -Unique
}

function Get-RemoteCommitDate {
	param ([string]$RemotePath)

	$uri = "https://api.github.com/repos/$repo/commits" +
	"?path=$([uri]::EscapeDataString($RemotePath))&sha=$branch&per_page=1"

	$commit = Invoke-RestMethod -Uri $uri -UseBasicParsing -ErrorAction Stop |
	Select-Object -First 1

	if (-not $commit) { return $null }

	([datetime]$commit.commit.committer.date).ToUniversalTime()
}

function Get-RemoteListing {
	# Один запрос к API: имя файла -> sha
	param ([string]$RemoteDir)

	$path = (@("src/$Version", $RemoteDir) | Where-Object { $_ }) -join "/"
	$uri = "https://api.github.com/repos/$repo/contents/${path}?ref=$branch"

	$items = Invoke-RestMethod -Uri $uri -UseBasicParsing -ErrorAction Stop
	$map = @{}
	foreach ($item in $items) {
		if ($item.type -eq "file") { $map[$item.name] = $item.sha }
	}
	$map
}

function Compare-WithRemote {
	param ([IO.FileInfo]$File, [hashtable]$Listing, [string]$RemoteDir)

	$path = (@("src/$Version", $RemoteDir, $File.Name) | Where-Object { $_ }) -join "/"
	$url = "https://raw.githubusercontent.com/$repo/refs/heads/$branch/$path"

	if (-not $Listing.ContainsKey($File.Name)) {
		Write-Warning "$($File.Name): отсутствует на GitHub"
		return
	}

	# 1. Содержимое совпадает: дату не запрашиваем
	if ((Get-LocalGitHashes -Path $File.FullName) -contains $Listing[$File.Name]) {
		Write-Verbose "$($File.Name): без изменений" -Verbose
		return
	}

	# 2. Содержимое отличается: сравниваем даты
	$remoteDate = Get-RemoteCommitDate -RepoPath $path
	$localDate = $File.LastWriteTimeUtc

	$fmt = "yyyy-MM-dd HH:mm"
	$dates = "локально: $($localDate.ToLocalTime().ToString($fmt)), GitHub: " +
	$(if ($remoteDate) { $remoteDate.ToLocalTime().ToString($fmt) } else { "неизвестно" })

	if ($remoteDate -and $remoteDate -le $localDate) {
		Write-Verbose "$($File.Name): отличается, но локальная версия новее ($dates). Пропуск" -Verbose
		return
	}

	Write-Verbose "$($File.Name): на GitHub новее ($dates). Запуск сравнения" -Verbose
	& $compare $File.FullName $url
}

try {
	# Module\Private
	$private = Get-RemoteListing -RemoteDir "Module/Private"
	$localPrivate = Get-ChildItem -Path "$localRoot\Module\Private" -File
	foreach ($file in $localPrivate) {
		Compare-WithRemote -File $file -Listing $private -RemoteDir "Module/Private"
	}

	# Новые файлы на GitHub, которых нет локально
	$private.Keys | Where-Object { $_ -notin $localPrivate.Name } | ForEach-Object {
		Write-Warning "$_ : новый файл на GitHub, локально отсутствует"
	}

	# Module\Sophia.psm1
	$module = Get-RemoteListing -RemoteDir "Module"
	Compare-WithRemote -File (Get-Item "$localRoot\Module\Sophia.psm1") -Listing $module -RemoteDir "Module"

	# Sophia.ps1
	$root = Get-RemoteListing -RemoteDir ""
	Compare-WithRemote -File (Get-Item "$localRoot\Sophia.ps1") -Listing $root -RemoteDir ""
}
catch {
	Write-Warning "GitHub API недоступен: $($_.Exception.Message)"
}
	
$script = (Resolve-Path (Join-Path $PSScriptRoot "$Version\Sophia.ps1")).Path

$PowerShellExe = if ($Version -match "PowerShell_7") {
	Join-Path -Path $PSHOME -ChildPath "pwsh.exe"
}
else {
	Join-Path -Path $PSHOME -ChildPath "powershell.exe"
}

$IsAdmin = ((New-Object -TypeName System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
if (-not $IsAdmin) {
	Start-Process -FilePath $PowerShellExe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -NoLogo -File `"$script`"" -Verb Runas
	exit
}
& $script