# You can use xRemoteAccess for greater configuration control
# https://github.com/mgreenegit/xRemoteAccess/

configuration InstallRRAS
{
   param
    (

    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node localhost
    {
        WindowsFeature Routing
        {
            Ensure = 'Present'
            Name = 'Routing'

        }
        WindowsFeature RemoteAccessPowerShell
        {
            Ensure = 'Present'
            Name = 'RSAT-RemoteAccess-PowerShell'
            DependsOn = '[WindowsFeature]Routing'
        }
        Service RemoteAccess
        {
            Name        = "RemoteAccess"
            StartupType = "Automatic"
            State       = "Running"
            DependsOn = '[WindowsFeature]Routing'
        }
        

    }
}