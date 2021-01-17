# A class to wrap WinSCP File transfer functionality for BackdoorsAndBreaches PowerShell Module

using module '.\ConfigFile.psm1'

class FileXfer {
    [String]$FTPSPathToWinSCPnetDLL
    [String]$FTPSTlsHostCertificateFingerprint
    [String]$SshHostKeyFingerprint
    [String]$FTPSecureMode

    [String]$URLforIncidentMaster
    [String]$URLforPlayers

    [String]$IncidentMasterUploadURI
    [String]$PlayerUploadURI
    [String]$Protocol

    [String]$Username
    [string]$SecurePassword
    [String]$URI        # doesn't contain protocol information
    [Int32]$Port

    [System.Object] $SessionOptions

    FileXfer( [String]$ConfigFilePath )
    {
        # TODO: Add Error checking and validations...
        $cfg=[ConfigFile]::new( $ConfigFilePath )
        $this.Protocol = $cfg.get( "TransferProtocol"  )
        $this.FTPSPathToWinSCPnetDLL = $cfg.get( "PathToWinSCPnetDLL"  )
        $this.URLforIncidentMaster = $cfg.get( "URLforIncidentMaster"  )
        $this.URLforPlayers = $cfg.get( "URLforPlayers"  )
        $this.IncidentMasterUploadURI = $cfg.get( "IncidentMasterUploadURI"  )
        $this.PlayerUploadURI = $cfg.get( "PlayerUploadURI"  )
        $this.URI = $cfg.get( "URI" )
        $this.Port= $cfg.get( $this.Protocol, "Port"  )

        # Initialise sessions options just the once
        Add-Type -Path $this.FTPSPathToWinSCPnetDLL
        $this.SessionOptions = New-Object WinSCP.SessionOptions
        $this.SessionOptions.HostName=$this.URI
        $this.SessionOptions.PortNumber=$this.Port.ToInt32( $null )
        $WinSCPProtocol = New-Object WinSCP.Protocol

        switch( $this.Protocol  ) {
            "FTPS" {
                $this.FTPSTlsHostCertificateFingerprint=$cfg.get( $this.Protocol, "TlsHostCertificateFingerprint"  )
                $this.FTPSecureMode = $cfg.get( $this.Protocol, "FTPSecure"  )
                $this.Username=$cfg.get( $this.Protocol, "Username"  )
                $this.SecurePassword = $cfg.get( $this.Protocol, "SecurePassword"  )
                if( $null -eq $this.SecurePassword )
                {
                    # Password not provided so prompt the user at runtime.  The password will be cached as secure string and decrypted at time of use.
                    $this.SecurePassword = Read-Host -Prompt "Enter FTPS password" -AsSecureString | ConvertFrom-SecureString
                }
                $this.SessionOptions.Protocol= $WinSCPProtocol::Ftp
                $this.SessionOptions.UserName=$this.Username
                $this.SessionOptions.SecurePassword=ConvertTo-SecureString( $this.SecurePassword )

                $WinSCPFTPSecure= New-Object WinSCP.FTPSecure
                switch( $this.FTPSecureMode ){
                    "Explicit" { $this.SessionOptions.FTPSecure=$WinSCPFTPSecure::Explicit; break }
                    "Implicit" { $this.SessionOptions.FTPSecure=$WinSCPFTPSecure::Implicit; break }
                }
                $this.SessionOptions.TlsHostCertificateFingerprint = $this.FTPSTlsHostCertificateFingerprint
                break
            }
            "SFTP" {
                # WARNING - Untested
                $this.Username=$cfg.get( $this.Protocol, "Username"  )
                $this.EncryptedPassword = $cfg.get( $this.Protocol, "SecurePassword" )
                $this.SshHostKeyFingerprint=$cfg.get( $this.Protocol, "SshHostKeyFingerprint"  )

                $this.SessionOptions.Protocol= $WinSCPProtocol::Sftp
                $this.SessionOptions.HostName=$this.URI
                $this.SessionOptions.UserName=$this.Username
                $this.SessionOptions.SshHostKeyFingerprint=$this.SshHostKeyFingerprint
            }
            "FTP" {
                $this.SessionOptions.Protocol= $WinSCPProtocol::Ftp
                $this.Username=$cfg.get( $this.Protocol, "Username"  )
                $this.SecurePassword = $cfg.get( $this.Protocol, "SecurePassword"  )
                if( $null -eq $this.SecurePassword )
                {
                    # Password not provided so prompt the user at runtime.  The password will be cached as secure string and decrypted at time of use.
                    $this.EncryptedPassword = Read-Host -Prompt "Enter FTP password" -AsSecureString | ConvertFrom-SecureString
                }
                $this.SessionOptions.HostName=$this.URI
                $this.SessionOptions.UserName=$this.Username
                $this.SessionOptions.SecurePassword=ConvertTo-SecureString( $this.SecurePassword )
                break
            }
        }
    }

    [void] UploadFile( [String] $Source, [String] $Target )
    {
        try {
            switch( $this.Protocol  ) {
                "FTPS" {
                    $session = New-Object WinSCP.Session
                    $session.Open($this.SessionOptions)
                    $session.PutFiles($Source, $Target ).Check()
                    $session.Dispose()
                    break
                }
                "FTP" {
                    $session = New-Object WinSCP.Session
                    $session.Open($this.SessionOptions)
                    $session.PutFiles($Source, $Target ).Check()
                    $session.Dispose()
                    break
                }
            }
        }
        catch {
                Write-Error -Message $_
                throw '[-] Error thrown in FileXfer UploadFile'
        }
    }

    [bool] FileExists( [String] $remotePath )
    {
        try{
            Add-Type -Path $this.FTPSPathToWinSCPnetDLL
            $session = New-Object WinSCP.Session
            $session.Open( $this.SessionOptions )
            if ($session.FileExists($remotePath))
            {
                $result = $true
            } else {
                $result = $false
            }
            $session.Dispose()
            return $result
        }
        catch {
                Write-Error -Message $_
                throw '[-] Error thrown in FileXfer FileExists'
        }
    }

    [bool] CreateDirectory( [String] $remotePath )
    {
        try{
            Add-Type -Path $this.FTPSPathToWinSCPnetDLL
            $session = New-Object WinSCP.Session
            $session.Open( $this.SessionOptions )
            $session.CreateDirectory($remotePath)
            if (  $this.FileExists( $remotePath ))
            {
                $result = $true
            } else {
                $result = $false
            }
            $session.Dispose()
            return $result
        }
        catch {
                Write-Error -Message $_
                throw '[-] Error thrown in FileXfer CreateDirectory'
        }
    }

    [void] UploadDirectory( [String] $SourceDirectory, [String]$TargetRemoteDirectory )
    {
        try{
            #$remotePath = "/home/user/test.txt"
            Add-Type -Path $this.FTPSPathToWinSCPnetDLL
            $session = New-Object WinSCP.Session
            $session.Open( $this.SessionOptions )
            if( $this.FileExists( $TargetRemoteDirectory ) -ne $true )
            {
                $this.CreateDirectory( $TargetRemoteDirectory )
            }
            $session.PutFilesToDirectory( $SourceDirectory, $TargetRemoteDirectory )

            $session.Dispose()
            return
        }
        catch {
                Write-Error -Message $_
                throw '[-] Error thrown in FileXfer UploadDirectory'
        }
    }

}
