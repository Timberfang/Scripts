function Get-DriveInfo {
	<#
		.SYNOPSIS
			Get used space on the computer's storage drives and issue a warning if usage exceeds 75%.
	#>

	[CmdletBinding()]
	param(
		[ValidateRange(1, [int]::MaxValue)]
		[Parameter(ValueFromPipeline)]
		[int]
		$WarnPercent = 75
	)

	begin { Set-StrictMode -Version 3 }

	process {
		$DriveInfo = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
			if (($_.Used / ($_.Free + $_.Used)).ToString("P") -ge $WarnPercent) {
				[PSCustomObject]@{
					Name         = $_.Name
					"Used (GB)"  = $_.Used
					"Free (GB)"  = $_.Free
					"Total (GB)" = ($_.Used + $_.Free)
					"Used (%)"   = (($_.Used / ($_.Free + $_.Used)).ToString("P") + ' - Warning!')
					Provider     = $_.Provider
					Root         = $_.Root
				}
			}
			else {
				[PSCustomObject]@{
					Name         = $_.Name
					"Used (GB)"  = $_.Used
					"Free (GB)"  = $_.Free
					"Total (GB)" = ($_.Used + $_.Free)
					"Used (%)"   = ($_.Used / ($_.Free + $_.Used)).ToString("P")
					Provider     = $_.Provider
					Root         = $_.Root
				}
			}
		}
		return $DriveInfo
	}
}

function Get-IPAddress {
	<#
		.SYNOPSIS
			Get the public and local IP addresses of the current computer.
		.DESCRIPTION
			Get the public and local IP addresses for the computer running the command. The local address can be retreived at any time,
			as long as the computer is connected to a network. The public address depends on the website ident.me for retrieving the address.
			If this website is down, the public address will not be displayed.
		.EXAMPLE
			PS C:\>.\Get-IPAddress.ps1

			LocalIP       PublicIP
			-------       --------
			192.0.2.0     203.0.113.0
	#>

	begin { Set-StrictMode -Version 3 }

	process {
		if (([System.Environment]::OSVersion.Platform -eq 'Win32NT')) {
			$LocalIP = Get-NetIPAddress -PrefixOrigin DHCP -ErrorAction SilentlyContinue
		}
		elseif ((Test-Path variable:IsLinux) -and ($IsLinux)) { $LocalIP = & hostname -i }
		elseif ((Test-Path variable:IsMacOS) -and ($IsMacOS)) { $LocalIP = & ipconfig getifaddr en0 }

		$IPAddress = [PSCustomObject]@{
			LocalIP  = if (Test-Path variable:LocalIP) { $LocalIP } else { 'None' }
			PublicIP = if (Test-Connection -Ping example.com -Quiet -Count 1) { Invoke-WebRequest -Uri 'https://ident.me/' } else { 'None' }
		}
		return $IPAddress
	}
}

function Get-SystemInfo {
	<#
		.SYNOPSIS
			List basic information about the computer.
		.DESCRIPTION
			Lists the computer name, user account, OS, CPU model, GPU model, currently installed RAM, motherboard model, currently running antivirus,
			local IP address, and public IP address.
		.NOTES
			This script only supports Microsoft Windows.
		.EXAMPLE
			PS C:\>.\Get-SystemInfo.ps1

			Name        : EXAMPLE-NAME
			OS          : Microsoft Windows 11 Home
			CPU         : Intel(R) Core(TM) i7-9900KF CPU @ 3.60GHz
			GPU         : NVIDIA GeForce RTX 3080
			RAM         : 31.96 GB
			Motherboard : ASUSTeK COMPUTER INC. - PRIME Z390-A
			Antivirus   : Windows Defender
			LocalIP     : 192.168.1.101
			PublicIP    : 203.0.113.17
	#>

	begin {
		Set-StrictMode -Version 3
		if (([System.Environment]::OSVersion.Platform -ne 'Win32NT')) { throw 'Windows is required to run this script.' }
	}

	process {
		$IPAddress = Get-IPAddress
		$BasicInfo = Get-ComputerInfo -Property CsName, CsTotalPhysicalMemory, OsName
		$Motherboard = Get-CimInstance -Class Win32_BaseBoard
		$SystemInfo = [PSCustomObject]@{
			Name        = $BasicInfo.CsName
			OS          = $BasicInfo.OsName
			CPU         = (Get-PnpDevice -Class Processor -PresentOnly | Select-Object -First 1).Name
			GPU         = (Get-PnpDevice -Class Display -PresentOnly).Name
			RAM         = "{0:n2} GB" -f ($BasicInfo.CsTotalPhysicalMemory / 1GB)
			Motherboard = ($Motherboard.Manufacturer + ' - ' + $Motherboard.Product)
			Antivirus   = Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName 'AntivirusProduct' | Select-Object -ExpandProperty displayName
			LocalIP     = $IPAddress.LocalIP
			PublicIP    = $IPAddress.PublicIP
		}
		return $SystemInfo
	}
}

function Get-PerformanceInfo {
	<#
		.SYNOPSIS
			Get the the CPU usage, RAM usage, and disk usage of the currently running computer.
		.DESCRIPTION
			Retrieve the CPU, RAM, and disk usage of the current system.
			Get-PerformanceStats assumes Megabytes as the default units, but it will switch to gigabytes if the megabyte values exceed 1,000.
		.NOTES
			This script only supports Microsoft Windows.
		.EXAMPLE
			Get-PerformanceStats.ps1
			Retrieve the perfomance of the current system.
	#>

	begin {
		Set-StrictMode -Version 3
		if (([System.Environment]::OSVersion.Platform -ne 'Win32NT')) { throw 'Windows is required to run this script.' }

		# Define performance counter paths
		$CPUCounterPath = '\Processor(_Total)\% Processor Time'
		$RAMCounterPath = '\Memory\Available MBytes'
		$DiskCounterPath = '\PhysicalDisk(_Total)\Disk Bytes/sec'
	}

	process {
		# Retrieve performance data - Get-Counter only exists on Windows
		$RawData = Get-Counter -Counter $CPUCounterPath, $RAMCounterPath, $DiskCounterPath

		# Calculate performance data
		$CPUUsage = [Math]::Round($RawData.CounterSamples[0].CookedValue, 2)
		$RAMUsage = [Math]::Round($RawData.CounterSamples[1].CookedValue, 2)
		$DiskUsage = [Math]::Round($RawData.CounterSamples[2].CookedValue / 1MB, 2)

		if ($RAMUsage -gt 1000) {
			$RAMUsage = [Math]::Round($RAMUsage / 1KB, 2)
			$RAMSuffix = 'GB'
		}
		else { $RAMSuffix = 'MB' }

		if ($DiskUsage -gt 1000) {
			$DiskUsage = [Math]::Round($DiskUsage / 1KB, 2)
			$DiskSuffix = 'GB/s'
		}
		else { $DiskSuffix = 'MB/s' }

		# Output performance data
		$PerformanceData = [PSCustomObject]@{
			CPU       = $CPUUsage
			RAM       = $RAMUsage
			RAMUnits  = $RAMSuffix
			Disk      = $DiskUsage
			DiskUnits = $DiskSuffix
		}
		return $PerformanceData
	}
}
