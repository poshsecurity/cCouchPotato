enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cCouchPotatoInstall
{
    [DscProperty(Key)]
    [string] $Ensure
             
    # Gets the resource's current state.
    [cCouchPotatoInstall] Get() 
    {
        # If CouchPotato is installed, check we have the latest version installed
        $Package = Get-Package -Name 'CouchPotato' -ErrorAction SilentlyContinue
        if ($null -ne $Package) 
        {
            $this.Ensure = [Ensure]::Present
        }
        else 
        {
            $this.Ensure = [Ensure]::Absent
        }
        return $this
    }
    
    # Sets the desired state of the resource.
    [void] Set() 
    {
        if ($this.Ensure -eq [Ensure]::Present)
        {
            # Get CouchPotato info from github
            $ReleaseInfo = $this.GetLatestVersion()
            
            $OSArchitecture = (Get-WmiObject Win32_OperatingSystem | Select-Object -Property OSArchitecture).OSArchitecture
            if ($OSArchitecture -eq '64-bit')
            {
                $SetupAsset = $ReleaseInfo.assets.where{$_.name.contains('win-amd64.installer.exe')}
            }
            else 
            {
                $SetupAsset = $ReleaseInfo.assets.where{$_.name.contains('win32.installer.exe')}
            }
            
            $DownloadURI = $SetupAsset.browser_download_url
            
            # Download from Github
            $DownloadDestination = Join-Path -Path $ENV:temp -ChildPath 'couchpotato-setup.exe'
            Invoke-WebRequest -Uri $DownloadURI -OutFile $DownloadDestination
            
            $InstallPath = Join-Path -Path ${env:ProgramFiles} -ChildPath 'CouchPotato'
            $ArgumentList = '/verysilent /norestart /DIR="{0}"' -f $InstallPath

            # Start install
            Start-Process -FilePath $DownloadDestination -ArgumentList $ArgumentList -Wait

            $ExecutablePath = Join-Path -Path $InstallPath -ChildPath 'CouchPotato.exe'
            schtasks.exe /create /tn CouchPotato /tr $ExecutablePath /ru system /SC 'OnStart' /rl HIGHEST
            schtasks.exe /run /tn CouchPotato
            
        }
        else
        {
            schtasks.exe /stop /tn CouchPotato
            schtasks.exe /delete /tn CouchPotato
            $InstallPath = Join-Path -Path ${env:ProgramFiles} -ChildPath 'CouchPotato'
            $Uninstaller = Join-Path -Path $InstallPath -ChildPath 'uninstall.exe'
            Start-Process -FilePath $Uninstaller -ArgumentList '/S' -Wait
            schtasks.exe /delete /tn CouchPotato
        }
    }
    
    # Tests if the resource is in the desired state.
    [bool] Test() 
    {
        # If CouchPotato is installed, check we have the latest version installed
        $Package = Get-Package -Name 'CouchPotato' -ErrorAction SilentlyContinue
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            if ($null -eq $Package)
            {
                return $false
            }
            else 
            {
                # Get CouchPotato info from github
                $GitVersion = $this.GetLatestVersion().tag_name.split('/')[1]

                # Get the Executable's version
                $InstallPath = Join-Path -Path ${env:ProgramFiles} -ChildPath 'CouchPotato'
                $ExecutablePath = Join-Path -Path $InstallPath -ChildPath 'CouchPotato.exe'
                $ExeVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ExecutablePath).FileVersion

                return ($ExeVersion -eq $GitVersion)    
            }
        }
        else 
        {
            # If it should be absent, check if null and return result
            return ($null -eq $Package) 
        }
    }

    [PSCustomObject] GetLatestVersion ()
    {
        $ReleaseInfo = Invoke-RestMethod -Uri 'https://api.github.com/repos/CouchPotato/CouchPotatoServer/releases/latest' -UseBasicParsing
        return $ReleaseInfo
    }
}
