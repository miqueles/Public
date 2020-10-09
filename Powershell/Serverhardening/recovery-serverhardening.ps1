cls
do {
    do {
        write-host "Server Hardening Recovery Menu"
        write-host "A - Recover SMBv1"
        write-host "B - Recover Legacy Protocols"
        write-host "C - Remove Hardening GPO"
        write-host "R - Restart Computer"
        write-host "X - Exit"
        write-host ""
        write-host -nonewline "Type your choice and press Enter: "
        
        $choice = read-host
        
        write-host ""
        
        $ok = $choice -match '^[abcrx]+$'
        
        if ( -not $ok) { write-host "Invalid selection" }
    } until ( $ok )
    
    switch -Regex ( $choice ) {
        "A"
        {
            write-host "Recover SMBv1"
            Install-WindowsFeature fs-smb1
        }
        
        "B"
        {
            write-host "Recover Legacy Protocols"
            Write-Host 'Reset IIS to weak and insecure SSL defaults...'
Write-Host '--------------------------------------------------------------------------------'

New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers' -Force
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\CipherSuites' -Force
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes' -Force
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms' -Force
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols' -Force

$os = Get-WmiObject -class Win32_OperatingSystem
if ([System.Version]$os.Version -lt [System.Version]'10.0.17763') {
  # Less than Windows 2019
  New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -Force
  New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client' -name DisabledByDefault -value 1 -PropertyType 'DWord'
}

New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -Force

Write-Host 'Reset .NET to weak and insecure SSL defaults...'
Remove-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" -name 'SystemDefaultTlsVersions' -Force
Remove-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" -name 'SchUseStrongCrypto' -Force
Remove-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -name 'SystemDefaultTlsVersions' -Force
Remove-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -name 'SchUseStrongCrypto' -Force
if (Test-Path 'HKLM:\SOFTWARE\Wow6432Node') {
  Remove-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727" -name 'SystemDefaultTlsVersions' -Force
  Remove-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727" -name 'SchUseStrongCrypto' -Force
  Remove-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" -name 'SystemDefaultTlsVersions' -Force
  Remove-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319" -name 'SchUseStrongCrypto' -Force
}

Write-Host 'Reset WinHttp to weak and insecure SSL defaults...'
Remove-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp' -name 'DefaultSecureProtocols' -Force
if (Test-Path 'HKLM:\SOFTWARE\Wow6432Node') {
  if ([System.Version]$os.Version -lt [System.Version]'10.0.17763') {
    Remove-ItemProperty -path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp' -name 'DefaultSecureProtocols' -Force
  } else {
    # Windows 2019
    Remove-Item 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp' -Force
  }
}

Write-Host 'Reset Windows Internet Explorer to weak and insecure SSL defaults...'
Remove-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name 'SecureProtocols' -Force
Remove-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings' -name 'SecureProtocols' -Force

        }

        "C"
        {
            write-host "You entered 'C'"
        }
        "R"
        {
            Restart-Computer             I
        }

    }
} until ( $choice -match "X" )