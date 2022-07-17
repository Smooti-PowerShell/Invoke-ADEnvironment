param (
	[Parameter(Mandatory = $True)]
	[SecureString]$DSRMPassword
)

Import-Module -Name .\modules\master.psm1

# # Confirm we have an elevated session.
# If (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
# 	Throw "You must run this from an elevated PowerShell session."
# }

# Convert secure string to plain text
$DSRMUnencryptedPassword = ConvertFrom-SecureString -SecureString $DSRMPassword -AsPlainText

# Check password complexity
Invoke-PasswordComplexity -Password $DSRMUnencryptedPassword

# Convert plain text password to secure string
$DSRMPassword = ConvertTo-SecureString $DSRMUnencryptedPassword -AsPlainText -Force

# Setup AD forrest
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Build-ADForrest -DSRMPassword $DSRMPassword -DomainName "testbed.local"

$scriptName = "New-ADTestUsers.ps1"
$params = @{
	TaskName = "Test"
	ScriptName = $scriptName
	TaskExecute = “$($Env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe”
	TaskArgument = "`"-NonInteractive -WindowStyle Normal -NoLogo -NoProfile -NoExit -Command `“&`”$($env:PSScriptRoot)\$($scriptName)`”"
}

# Schedule task
Invoke-Task @params

# Apply changes
Restart-Computer