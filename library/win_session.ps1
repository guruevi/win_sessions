#!powershell

# Copyright: (c) 2020, Evi Vanoost <evi.vanoost@gmail.com>
# Based on previous work of:
# Copyright: (c) 2019, Simon Baerlocher <s.baerlocher@sbaerlocher.ch> 
# Copyright: (c) 2019, ITIGO AG <opensource@itigo.ch> 
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.ArgvParser
#Requires -Module Ansible.ModuleUtils.CommandUtil
#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$params = Parse-Args -arguments $args -supports_check_mode $false

$user = Get-AnsibleParam -obj $params -name "user" -type "str" -failifempty $true
$state = Get-AnsibleParam -obj $params -name "state" -type "str" -default "logout" -validateset "logout", "locked"
$failifempty = Get-AnsibleParam -obj $params -name "failifempty" -type "bool" -default $false

# Create a new result object
$result = @{
    changed = $false
}

if ($state -eq "logout") {
    try {
        ## Find all sessions matching the specified username
        $sessions = quser | Where-Object {$_ -match $user} -ErrorAction SilentlyContinue
        ## Parse the session IDs from the output
        $sessionIds = ($sessions -split ' +')[2]
        ## Loop through each session ID and pass each to the logoff command
        $sessionIds | ForEach-Object {
            logoff $_
            $rc = $?
            if($rc) {
                $result.changed = $true
            } else {
                Write-Error "Unable to log off $user" -ErrorAction Continue
                exit $rc
            }
        }

    } catch {
        #make the distinction between no results vs. query failure
        if($_.exception.message -ne 'No User exists for *'){
            if ($failifempty) {
                Write-Error $_.exception.message
            }
        } else {
            Write-Error $_.exception.message
        }
    }
}

if ($state -eq "locked") {
    try {
        if (quser | Where-Object {$_ -match $user -and $_ -match "console"}) {
            $xCmdString = {rundll32.exe user32.dll,LockWorkStation}
            Invoke-Command $xCmdString
            $result.changed = $true
        }
    } catch {
        if($_.exception.message -ne 'No User exists for *'){
            if ($failifempty) {
                Write-Error $_.exception.message
            }
        } else {
            Write-Error $_.exception.message
        }
    }
}

# Return result
Exit-Json -obj $result
