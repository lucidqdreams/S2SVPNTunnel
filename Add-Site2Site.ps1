param
    (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $TargetRRASIP,
        [Parameter(Mandatory=$true,Position=2)]
        [String] $TargetIPRange,
        [Parameter(Mandatory=$true,Position=3)]     
        [String] $SharedSecret
    )


$S2SName = ($TargetIPRange.Replace('.','')).Replace('/','')
Write-Output "Creating Tunnel called $S2SName"

$TargetIPRangeMetric = $TargetIPRange + ':100'

Write-Output "Tunnel EndPoint: $TargetRRASIP"
Write-Output "Subnet and Metric in Tunnel: $TargetIPRangeMetric"

Write-Output "Checking Routing Installation"
$RoutingInstallation = get-windowsfeature routing
if ($RoutingInstallation.Installed)
{
    Write-Output "Routing Already Installed"
}
else
{
    Write-Output 'Installing Routing'
    Install-WindowsFeature Routing -IncludeManagementTools -Confirm:$false -Verbose
    start-sleep 10
    Write-Output 'Set Automatic Start for RemoateAccess'
    Set-Service -Name "remoteaccess" -StartupType Automatic -Confirm:$false -Verbose
    Write-Output 'Start RemoateAccess Service '
    Start-Service -Name "remoteaccess" -Confirm:$false -Verbose
    start-sleep 10
}


$RRASInstalled = (Get-RemoteAccess).VpnS2SStatus
if ($RRASInstalled -ne 'Installed')
{
    write-output 'Installing VpnS2S'
    Install-RemoteAccess -VpnType VpnS2S -Verbose
    start-sleep 10

}
else
{
    write-output 'VpnS2S Installed'
}

$existing = get-VpnS2SInterface | where {$_.name -eq $S2SName}
if ($existing.name -eq $S2SName)
{
    Write-Output "Existing Tunnel $S2SName Found, Deleting..."
    disconnect-VpnS2SInterface -Name $S2SName -Confirm:$false -Force 
    remove-VpnS2SInterface -Name $S2SName -Confirm:$false -Force
}

Write-Output "Configuring Tunnel $S2SName"
try 
{
    Add-VpnS2SInterface -Name $S2SName $TargetRRASIP -Protocol IKEv2 -AuthenticationMethod PSKOnly -SharedSecret $SharedSecret -IPv4Subnet $TargetIPRangeMetric -persistent -AutoConnectEnabled $true
    Set-VpnS2SInterface -Name $S2SName  -InitiateConfigPayload $false 
    start-sleep 5
    $result = get-VpnS2SInterface -name $S2SName
    Write-Output "Tunnel Created, Status: $($result.ConnectionState)"
}
catch{}
Finally{
    start-sleep 60
    $result = get-VpnS2SInterface -name $S2SName
}

return "Tunnel Status: $($result.ConnectionState)"



