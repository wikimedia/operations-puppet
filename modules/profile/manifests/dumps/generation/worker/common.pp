class profile::dumps::generation::worker::common(
    $nfs_server = hiera('dumps_nfs_server'),
    $managed_subdirs = hiera('dumps_managed_subdirs'),
    $datadir_mount_type = hiera('dumps_datadir_mount_type'),
    $extra_mountopts = hiera('profile::dumps::generation::worker::common::nfs_extra_mountopts'),
    $php = hiera('profile::dumps::generation::worker::common::php'),
) {
    # mw packages and dependencies
    require ::profile::mediawiki::scap_proxy
    require ::profile::mediawiki::common
    require ::profile::mediawiki::nutcracker

    $xmldumpsmount = '/mnt/dumpsdata'

    class { '::dumpsuser': }

    snapshot::dumps::datamount { 'dumpsdatamount':
        mountpoint      => $xmldumpsmount,
        mount_type      => $datadir_mount_type,
        extra_mountopts => $extra_mountopts,
        server          => $nfs_server,
        managed_subdirs => $managed_subdirs,
        user            => 'dumpsgen',
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
    class { '::snapshot::dumps': php => $php}

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
