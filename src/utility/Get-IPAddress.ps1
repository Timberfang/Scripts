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
$LocalIP = Get-NetIPAddress -PrefixOrigin DHCP -ErrorAction SilentlyContinue

$IPAddress = [PSCustomObject]@{
	LocalIP =
		if ($null -ne $LocalIP) {$LocalIP}
		else { 'None' }
	PublicIP =
		if (Test-Connection -Ping example.com -Quiet -Count 1) { Invoke-WebRequest -Uri 'https://ident.me/' }
		else { 'None' }
}
Write-Output $IPAddress
