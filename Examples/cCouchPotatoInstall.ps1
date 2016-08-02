configuration DownloadHostDSC
{
    Import-DscResource -ModuleName 'cCouchPotato'

    cCouchPotatoInstall CouchPotatoInstaller
    {
        Ensure    = 'Present'
    }
}
