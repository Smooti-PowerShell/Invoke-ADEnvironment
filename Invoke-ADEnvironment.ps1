param (
	[Parameter(Mandatory = $True)]
	[SecureString]$DSRMPassword,

	[Parameter(Mandatory = $True)]
	[string]$DomainName,

	[Parameter(Mandatory = $False)]
	[switch]$CreateTestUsers
)

Import-Module -Name .\modules\master.psm1

# Confirm we have an elevated session.
If (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Throw ("You must run this from an elevated PowerShell session.")
}

#Getting information from the json file
$config = Get-Content "$($PSScriptRoot)\config.json" | ConvertFrom-Json

# Create test user accounts in active directory
if ($CreateTestUsers) {
	# Verify credentials locally
	$creds = Get-Credential -UserName $env:UserName -Message "Local Account Password"
	$password = $creds.Password
	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	$DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)
	$credentialsValid = $DS.ValidateCredentials($creds.UserName, $creds.GetNetworkCredential().Password)
	if ($credentialsValid -ne "True") {
		throw ("The local credentials that you have provided are invalid.")
	}

	# Create active directory credentials
	$adCreds = New-Object System.Management.Automation.PSCredential ("$($DomainName)\$($creds.UserName)", $password)

	# Export reusable items to temporary file
	$adCreds | Export-Clixml -Path "C:\tempCred.xml" -Force
	$scriptName = "$($PSScriptRoot)\New-ADTestUsers.ps1"
	$params = @{
		TaskName     = $config.InvokeTask.TaskName
		TaskExecute  = “$($Env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe”
		TaskArgument = "-NonInteractive -WindowStyle Hidden -NoLogo -NoProfile -Command `“& $($scriptName)`”"
	}

	# Schedule task
	Invoke-Task @params
}

# Setup AD forrest
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Try {
	Build-ADForrest -DSRMPassword $DSRMPassword -DomainName $DomainName
	Read-Host ("Press enter to reboot the machine and finish the install")
}
Catch {

}
# Apply changes
Restart-Computer