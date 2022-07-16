# * Confirm we have an elevated session.
If (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Throw "You must run this from an elevated PowerShell session."
}

Write-Verbose "Installing `"AD-Domain-Services`""
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
[securestring]$Password = Read-Host -Prompt 'Enter SafeMode Admin Password' -AsSecureString

# AD Forrest parameters
$Params = @{
	CreateDnsDelegation           = $false
	DatabasePath                  = 'C:\Windows\NTDS'
	DomainMode                    = 'WinThreshold'
	DomainName                    = 'testbed.local'
	ForestMode                    = 'WinThreshold'
	InstallDns                    = $true
	LogPath                       = 'C:\Windows\NTDS'
	NoRebootOnCompletion          = $true
	SafeModeAdministratorPassword = $Password
	SysvolPath                    = 'C:\Windows\SYSVOL'
	Force                         = $true
}

# Create Forrest
Install-ADDSForest @Params

