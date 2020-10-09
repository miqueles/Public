function DisablingServicesOnServer2016wDE{
<#
.SYNOPSIS
	Disable extraneous services on Server 2016 Desktop Experience
.DESCRIPTION
	Disable extraneous services on Server 2016 Desktop Experience
.PARAMETER  ComputerName
    Disabled the services installed on the specified server. The default is the local computer.
.PARAMETER  PathFolder
	Specifies a path to log folder location.The default location is $env:USERPROFILE+'\DisablingServices\'
.EXAMPLE
	DisablingServicesOnServer2016wDE -ComputerName srv01 -PathFolder C:\temp\DisabledServices\
.OUTPUTS
	Log file.
.NOTES
    Name: DisablingServicesOnServer2016wDE
    Author: CarlosDZRZ
    DateCreated: 12/23/2017
.LINK
    https://gist.github.com/xtratoast/dea055ec0e1a31d91161b6d431e90146
    https://blogs.technet.microsoft.com/secguide/2017/05/29/guidance-on-disabling-system-services-on-windows-server-2016-with-desktop-experience/
    https://docs.microsoft.com/en-us/windows-server/security/windows-services/security-guidelines-for-disabling-system-services-in-windows-server
    https://docs.microsoft.com/en-us/windows/application-management/per-user-services-in-windows
    https://technet.microsoft.com/en-us/library/cc959920.aspx	
#>
[CmdletBinding()]    
param(
    [String]$ComputerName = $env:COMPUTERNAME,
    [ValidateSet('ShouldBeDisabledOnly','ShouldBeDisabledAndDefaultOnly','OKToDisable','OKToDisablePrinter','OKToDisableDC')]
    [String]$Level = 'OKToDisablePrinter',
    [string]$PathFolder = $env:USERPROFILE+'\DisabledServices\'
)
Begin{
	$filename = "DisabledServices_" + $ComputerName
	Write-Verbose $PathFolder
	if (!(Test-Path -Path $PathFolder -PathType Container)){
		New-Item -Path $PathFolder  -ItemType directory
		Write-Host -ForegroundColor Green "Create a new folder"
	}
	$filepath = $PathFolder + $filename +'.log'
    $stream = [System.IO.StreamWriter] $filepath
    #Set-Service : Service 'Contact Data (PimIndexMaintenanceSvc)' cannot be configured due to the following error: Access is denied. I need modify registry.
    [String[]]$Regedit_services = @(
                                        "CDPUserSvc",
                                        "PimIndexMaintenanceSvc",
                                        "OneSyncSvc",
                                        "UnistoreSvc",
                                        "UserDataSvc",
                                        "WpnUserService",
                                        "NgcSvc",
                                        "NgcCtnrSvc"
                                    )
    [String[]]$DisabledByDefault = @(
                                        "tzautoupdate",
                                        "Browser",
                                        "AppVClient",
                                        "CscService",
                                        "RemoteAccess",
                                        "SCardSvr",
                                        "UevAgentService",
                                        "WSearch"
                                    )
    [String[]]$ShouldBeDisabled = @(
                                        "XblAuthManager",
                                        "XblGameSave"
                                    )
    [String[]]$OKToDisable = @(
                                        "AxInstSV",
                                        "bthserv",
                                        "dmwappushservice",
                                        "MapsBroker",
                                        "lfsvc",
                                        "SharedAccess",
                                        "lltdsvc",
                                        "wlidsvc",
                                        "NcbService",
                                        "PhoneSvc",
                                        "PcaSvc",
                                        "QWAVE",
                                        "RmSvc",
                                        "SensorDataService",
                                        "SensrSvc",
                                        "SensorService",
                                        "ShellHWDetection",
                                        "ScDeviceEnum",
                                        "SSDPSRV",
                                        "WiaRpc",
                                        "TabletInputService",
                                        "upnphost",
                                        "WalletService",
                                        "Audiosrv",
                                        "AudioEndpointBuilder",
                                        "FrameServer",
                                        "stisvc",
                                        "wisvc",
                                        "icssvc",
                                        "WpnService"
                                )
    [String[]]$OKToDisableNotDCorPrint = @('Spooler')
    [String[]]$OKToDisableNotPrint = @('PrintNotify')
    [String[]]$ServicesToDisable = @()

    switch($Level)
    {
        'ShouldBeDisabledOnly'           { $ServicesToDisable += $ShouldBeDisabled }
        'ShouldBeDisabledAndDefaultOnly' { $ServicesToDisable += $ShouldBeDisabled + $DisabledByDefault }
        'OKToDisablePrinter'             { $ServicesToDisable += $ShouldBeDisabled + $DisabledByDefault + $OKToDisable + $Regedit_services}
        'OKToDisableDC'                  { $ServicesToDisable += $ShouldBeDisabled + $DisabledByDefault + $OKToDisable + $OKToDisableNotDCorPrint + $Regedit_services }
        'OKToDisable'                    { $ServicesToDisable += $ShouldBeDisabled + $DisabledByDefault + $OKToDisable + $OKToDisableNotDCorPrint + $OKToDisableNotPrint + $Regedit_services }
    }        
}
Process{
    $InstalledServices = Get-Service -ComputerName $ComputerName

    foreach($Service in $ServicesToDisable)
    {
        if ($Regedit_services -contains $Service){
            #Set-ItemProperty not ComputerName parameter
            if ($ComputerName -eq $env:COMPUTERNAME){
                #localhost
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Service" -Name "Start" -value 4
                $stream.WriteLine("Disabled service: $Service")
            }
            else{
                #remote server
                Invoke-Command -ScriptBlock {Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($args[0])" -Name "Start" -value 4} -ArgumentList $Service -ComputerName $ComputerName
                $stream.WriteLine("Disabled service: $Service")
            }            
        }
        elseif($InstalledServices.Name -contains $Service){
            Set-Service -Name $Service -ComputerName $ComputerName -StartupType Disabled
            $stream.WriteLine("Disabled service: $Service")
        }
    }    
}
End{
    $stream.close()
}    
}#end function DisablingServicesOnServer2016wDE