<#
	.SYNOPSIS
		List basic information about the computer.
	.DESCRIPTION
		Lists the computer name, user account, OS, CPU model, GPU model, currently installed RAM, motherboard model, currently running antivirus,
		local IP address, and public IP address.

		This script currently runs only on Windows due to the lack of the Get-ComputerInfo, Get-PnpDevice, and Get-CimInstance cmdlets on MacOS and Linux.
	.EXAMPLE
		PS C:\>.\Get-SystemInfo.ps1

		Name        : EXAMPLE-NAME
		Owner       : user@exampledomain.com
		OS          : Microsoft Windows 11 Home
		CPU         : Intel(R) Core(TM) i7-9900KF CPU @ 3.60GHz
		GPU         : NVIDIA GeForce RTX 3080
		RAM         : 31.96 GB
		Motherboard : ASUSTeK COMPUTER INC. - PRIME Z390-A
		Antivirus   : Windows Defender
		LocalIP     : 192.0.2.0
		PublicIP    : 203.0.113.0
#>

$LocalIP = Get-NetIPAddress -PrefixOrigin DHCP -ErrorAction SilentlyContinue
$BasicInfo = Get-ComputerInfo -Property CsName,CsTotalPhysicalMemory,CsPrimaryOwnerName,OsName
$Motherboard = Get-CimInstance -Class Win32_BaseBoard
$SystemInfo = [PSCustomObject]@{
	Name = $BasicInfo.CsName
	Owner = $BasicInfo.CsPrimaryOwnerName
	OS = $BasicInfo.OsName
	CPU = (Get-PnpDevice -Class Processor -PresentOnly | Select-Object -First 1).Name
	GPU = (Get-PnpDevice -Class Display -PresentOnly).Name
	RAM = "{0:n2} GB" -f ($BasicInfo.CsTotalPhysicalMemory / 1GB)
	Motherboard = ($Motherboard.Manufacturer + ' - ' + $Motherboard.Product)
	Antivirus = Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName 'AntivirusProduct' | Select-Object -ExpandProperty displayName
	LocalIP =
		if ($null -ne $LocalIP) {$LocalIP}
		else { 'None' }
	PublicIP =
		if (Test-Connection -Ping example.com -Quiet -Count 1) { Invoke-WebRequest -Uri 'https://ident.me/' }
		else { 'None' }
}

Write-Output $SystemInfo
