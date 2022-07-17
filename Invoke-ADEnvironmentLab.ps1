param (
	[Parameter(Mandatory = $True)]
	[securestring]$DSRMPassword
)

Import-Module -Name .\modules\master.psm1

# Confirm we have an elevated session.
If (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Throw "You must run this from an elevated PowerShell session."
}

# Convert secure string to plain text
$DSRMPassword = ConvertFrom-SecureString $DSRMPassword -AsPlainText -Force

# Check password complexity
Check-PasswordComplexity -Password $DSRMPassword

# Convert plain text password to secure string
$DSRMPassword = ConvertTo-SecureString $DSRMPassword -AsPlainText -Force

# Setup AD forrest
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Build-ADForrest $NewHostName $DSRMPassword

# Create test users
New-ADTestUsers