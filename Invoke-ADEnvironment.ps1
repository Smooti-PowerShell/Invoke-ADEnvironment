param (
	[Parameter(Mandatory = $True)]
	[SecureString]$DSRMPassword,

	[Parameter(Mandatory = $True)]
	[string]$DomainName
)

Import-Module -Name .\modules\master.psm1

# Confirm we have an elevated session.
If (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Throw ("You must run this from an elevated PowerShell session.")
}

# Setup AD forrest
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment

Try {
	Invoke-Forrest -DSRMPassword $DSRMPassword -DomainName $DomainName
	Read-Host ("Press enter to reboot the machine and finish the install")
}
Catch {
	Throw ($_)
}
# Apply changes
Restart-Computer