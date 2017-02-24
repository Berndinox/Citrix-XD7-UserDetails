<#
        .Synopsis
           USerDetails
        .DESCRIPTION
           Citrix User-Details to Array Function
        .EXAMPLE
           Get-CtxUser
           Get-CtxUser -log 1 -CTXItems "ClientAddress"
           Get-CtxUser -CTXItems "ClientName","UserSid"
        .AUTHOR
           Bernd KLAUS
        .VERSION
           1
        .DATE
           24.02.2017
#>

function Get-CtxUser
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$false, 
                   ValueFromPipelineByPropertyName=$true)] 
        [Alias("Items")] 
        $CTXItems=("ClientAddress","ClientName","ClientVersion","ConnectedViaIpAddress","UserName","PublishedName","UserLogonTime","UserSid","DomainName"),
         
        [Parameter(Mandatory=$false,Position=0)] 
        [bool]$log
    ) 
    if ($log) { Write-Host "Start collecting Data" }
    $username = $env:USERNAME
    $citrixarray = $null; $citrixarray = New-Object psobject
    if (Test-Path HKLM:\Software\Citrix\Ica\Session)
    {
        if ($log) { Write-Host "HKLM:\Software\Citrix\Ica\Session Path found" }
        $sessions =  Get-ChildItem -PAth HKLM:\Software\Citrix\Ica\Session | Where-Object { ($_.Name -notlike "*CtxSessions*") -and ($_.Name -notlike "*RestartICA*")  } | select *
        foreach ($session in $sessions)
        {
            if ($log) { Write-Host "Scanning Session $($session.PSChildName) if it matches the current user: $username" }
            $path = $session.name.Replace("HKEY_LOCAL_MACHINE","HKLM:") + "\Connection"
            if (((Get-ItemProperty $path -Name UserName).Username) -eq $username)
            {
                if ($log) { Write-Host "Found the propper session: $($session.PSChildName), start collecting Details" }
                $citrixarray = New-Object psobject
                function Get-CtxItems($items)
                {
                    foreach ($item in $items)
                    {
                        $tmp = $null
                        $tmp = (Get-ItemProperty $path -Name $item -ErrorAction SilentlyContinue).$item
                        if ($tmp -eq $null) { $tmp = "detect failed"; if ($log) { Write-Host "Detecting $item failed" }}
                        $citrixarray | add-member –membertype NoteProperty –name $item –value $tmp
                        if(($?) -and ($log)) { Write-Host "Added Item $item with Value $tmp" }
                        elseif ((!($?)) -and ($log)) { Write-Host "Failed adding Item $item with Value $tmp" }
                    }
                }
                Get-CtxItems $CTXItems
                if ($log) { Write-Host "Finished collecting Items, Output:" }
                return $citrixarray
            }
        }
     }
     else
     {
        if ($log) { Write-Host "Failed: No Citrix-Worker Server?" }
        return $false
     }
}

echo "--------------------------Examples-------------------------------"
Get-CtxUser
echo "-----------------------------------------------------------------"
Get-CtxUser -log 1 -CTXItems "ClientAddress"
echo "-----------------------------------------------------------------"
Get-CtxUser -CTXItems "ClientName","UserSid"