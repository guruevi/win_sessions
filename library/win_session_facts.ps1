#!powershell

#Requires -Module Ansible.ModuleUtils.ArgvParser
#Requires -Module Ansible.ModuleUtils.CommandUtil
#Requires -Module Ansible.ModuleUtils.Legacy

# Based on: Jaap Brasser's script https://gallery.technet.microsoft.com/scriptcenter/Get-LoggedOnUser-Gathers-7cbe93ea

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

Function Get-LoggedOnUsers {
    quser 2>&1 | Select-Object -Skip 1 | ForEach-Object {
        $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
        $HashProps = @{
            UserName = $CurrentLine[0]
        }

        # If session is disconnected different fields will be selected
        if ($CurrentLine[2] -eq 'Disc') {
            $HashProps.SessionName = $null
            $HashProps.Id = $CurrentLine[1]
            $HashProps.State = $CurrentLine[2]
            $HashProps.IdleTime = $CurrentLine[3]
            $HashProps.LogonTime = $CurrentLine[4..6] -join ' '
            $HashProps.LogonTime = $CurrentLine[4..($CurrentLine.GetUpperBound(0))] -join ' '
        } else {
            $HashProps.SessionName = $CurrentLine[1]
            $HashProps.Id = $CurrentLine[2]
            $HashProps.State = $CurrentLine[3]
            $HashProps.IdleTime = $CurrentLine[4]
            $HashProps.LogonTime = $CurrentLine[5..($CurrentLine.GetUpperBound(0))] -join ' '
        }

        New-Object -TypeName PSCustomObject -Property $HashProps |
                Select-Object -Property UserName,SessionName,Id,State,IdleTime,LogonTime,Error
    }
}

# Create a new result object
$result = @{
    changed       = $false
    ansible_facts = @{
        user_sessions = @()
    }
}

$result.ansible_facts.user_sessions = @(Get-LoggedOnUsers)

Exit-Json -obj $result
