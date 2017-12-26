class profile::dumps::generation::worker::common(
    $nfs_server = hiera('dumps_nfs_server')
    $managed_subdirs = hiera('dumps_managed_subdirs')
) {
    # mw packages and dependencies
    require ::profile::mediawiki::scap_proxy
    require ::profile::mediawiki::common
    require ::profile::mediawiki::nutcracker

    $xmldumpsmount = '/mnt/dumpsdata'

    class { '::dumpsuser': }

    snapshot::dumps::nfsmount { 'dumpsdatamount':
        mountpoint      => $xmldumpsmount,
        server          => $nfs_server,
        managed_subdirs => $managed_subdirs,
        user            => 'dumpsgen'
        group           => 'dumpsgen',
    }
    # dataset server config files,
    # stages files, dblists, html templates
    class { '::snapshot::dumps::dirs':
        user               => 'dumpsgen',
        xmldumpsmount      => $xmldumpsmount,
        xmldumpspublicdir  =>  "${xmldumpsmount}/xmldatadumps/public",
        xmldumpsprivatedir =>  "${xmldumpsmount}/xmldatadumps/private",
        dumpstempdir       =>  "${xmldumpsmount}/xmldatadumps/temp",
        cronsdir           =>  "${xmldumpsmount}/otherdumps",
        apachedir          => '/srv/mediawiki',
    }
    class { '::snapshot::dumps': }

    # scap3 deployment of dump scripts
    scap::target { 'dumps/dumps':
        deploy_user => 'dumpsgen',
        manage_user => false,
        key_name    => 'dumpsdeploy',
    }
    ssh::userkey { 'dumpsgen':
        content => secret('keyholder/dumpsdeploy.pub'),
    }
}
