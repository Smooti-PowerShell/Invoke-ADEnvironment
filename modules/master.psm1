function Invoke-Forrest {
	param (
		[Parameter (Mandatory = $True)]
		[securestring]$DSRMPassword,

		[Parameter (Mandatory = $True)]
		[string]$DomainName
	)

	$ErrorActionPreference = "Stop"

	# Installing AD Domain Services
	Write-Verbose "Installing `"AD-Domain-Services`""

	# AD Forrest parameters
	$params = @{
		CreateDnsDelegation           = $false
		DatabasePath                  = 'C:\Windows\NTDS'
		DomainMode                    = 'WinThreshold'
		DomainName                    = $DomainName
		ForestMode                    = 'WinThreshold'
		InstallDns                    = $true
		SafeModeAdministratorPassword = $DSRMPassword
		LogPath                       = 'C:\Windows\NTDS'
		NoRebootOnCompletion          = $true
		SysvolPath                    = 'C:\Windows\SYSVOL'
		Force                         = $true
	}

	# Create Forrest
	Install-ADDSForest @params
}

function Invoke-PasswordComplexity {
	param (
		[Parameter(Mandatory = $True)]
		[string]$Password
	)
	# Password Check
	$minLength = 7
	$minRequirements = 3
	# ? HashTable Layout --> @{ <Check> = [int]<Minimum Matching Characters>, [String]"Error Message"}
	$requirements = @{
		[regex]"[A-Z]"        = 1, "The password does not contain an upper-case character.";
		[regex]"[a-z]"        = 1, "The password does not contain a lower-case character.";
		[regex]"[0-9]"        = 1, "The password does not contain a number.";
		[regex]"[^a-zA-Z0-9]" = 1, "The password does not contain a special character."
	}
	$forbiddenPasswords = @(
		'P@$$w0rd',
		'$ecretW0rd'
	)

	# Check password length
	if ($Password.length -lt $minLength) {
		throw ("The password does not have at least $minLength characters.")
	}

	# Check blacklist
	if ($forbiddenPasswords -contains $Password) {
		throw ("The password is forbidden.")
	}

	# Passwords must not contain the user's entire samAccountName (Account Name) value.
	if ($Password.ToLower().Contains($env:username.SubString(0, 3))) {
		throw ("The password should not contain the username or parts of it.")
	}

	# Check whether the password meets at least 3 complexity requirements
	$requirementsPassed = 0
	$errorMessages = @()
	foreach ($requirement in $requirements.Keys) {
		$minMatchingCharacters = ($requirements[$requirement])[0]
		$matchingCharacters = $requirement.Matches($Password).Count
		$errorMessage = ($requirements[$requirement])[1]

		if ($matchingCharacters -lt $minMatchingCharacters) {
			$errorMessages += $errorMessage
			continue
		}

		$requirementsPassed++
	}

	# If the password does not meet the specified number of requirements, cancel operation
	if ($requirementsPassed -lt $minRequirements) {
		$requirementsCount = $requirements.Count

		foreach ($message in $errorMessages) {
			Write-Host ($message) -ForegroundColor Red
		}

		throw ("The password must meet at least $minRequirements out of $requirementsCount complexity requirements.")
	}
}

function Invoke-Task {
	param (
		[Parameter(Mandatory = $True)]
		[string]$TaskName,

		[Parameter(Mandatory = $True)]
		[string]$TaskExecute,

		[Parameter(Mandatory = $True)]
		[string]$TaskArgument
	)

	$ErrorActionPreference = "Stop"

	# Remove task if exists
	Get-ScheduledTask -TaskName $TaskName -ErrorAction Ignore | Unregister-ScheduledTask -Confirm:$false

	# Setup task
	$taskAction = New-ScheduledTaskAction -Execute $TaskExecute -Argument $TaskArgument
	$taskTrigger = New-ScheduledTaskTrigger -AtStartup
	$taskSetting = New-ScheduledTaskSettingsSet -MultipleInstances Parallel
	$taskPrincipal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
	$params = @{
		TaskName = $TaskName
		Action   = $taskAction
		Trigger  = $taskTrigger
		Settings = $taskSetting
		Principal = $taskPrincipal
	}

	# Register Task
	Register-ScheduledTask @params
}