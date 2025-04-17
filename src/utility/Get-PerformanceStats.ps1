<#
.SYNOPSIS
	Get the the CPU usage, RAM usage, and disk usage of the currently running computer.
.DESCRIPTION
	Retrieve the CPU, RAM, and disk usage of the current system.
	Get-PerformanceStats assumes Megabytes as the default units, but it will switch to gigabytes if the megabyte values exceed 1,000.
.NOTES
	Currently this script only supports Microsoft Windows.
.EXAMPLE
	Get-PerformanceStats.ps1
	Retrieve the perfomance of the current system.
#>

[CmdletBinding()]
param (
	[Parameter()]
	[ValidateSet('SilentlyContinue','Stop','Continue','Inquire','Suspend','Break')]
	[String]
	$InformationPreference = 'Continue'
)

# Define performance counter paths
$CPUCounterPath = '\Processor(_Total)\% Processor Time'
$RAMCounterPath = '\Memory\Available MBytes'
$DiskCounterPath = '\PhysicalDisk(_Total)\Disk Bytes/sec'

# Retrieve performance data
$RawData = Get-Counter -Counter $CPUCounterPath, $RAMCounterPath, $DiskCounterPath

# Calculate performance data
$CPUUsage = [Math]::Round($RawData.CounterSamples[0].CookedValue, 2)
$RAMUsage = [Math]::Round($RawData.CounterSamples[1].CookedValue, 2)
$DiskUsage = [Math]::Round($RawData.CounterSamples[2].CookedValue / 1MB, 2)

if($RAMUsage -gt 1000){
	$RAMUsage = [Math]::Round($RAMUsage / 1KB, 2)
	$RAMSuffix = 'GB'
}
else {$RAMSuffix = 'MB'}

if($DiskUsage -gt 1000){
	$DiskUsage = [Math]::Round($DiskUsage / 1KB, 2)
	$DiskSuffix = 'GB/s'
}
else {$DiskSuffix = 'MB/s'}

# Output performance data
Write-Information "CPU Usage: $CPUUsage%"
Write-Information "RAM Usage: $RAMUsage $RAMSuffix"
Write-Information "Disk Usage: $DiskUsage $DiskSuffix"
