# SPDX-License-Identifier: Apache-2.0
class profile::dumps::generation::worker::common(
    $dumps_nfs_server = lookup('dumps_nfs_server'),
    $cron_nfs_server = lookup('dumps_cron_nfs_server'),
    $managed_subdirs = lookup('dumps_managed_subdirs'),
    $datadir_mount_type = lookup('dumps_datadir_mount_type'),
    $extra_mountopts = lookup('profile::dumps::generation::worker::common::nfs_extra_mountopts'),
    $php = lookup('profile::dumps::generation::worker::common::php'),
    $dumps_misc_cronrunner = lookup('profile::dumps::generation::worker::common::dumps_misc_cronrunner'),
) {
    # mw packages and dependencies
    require profile::mediawiki::scap_proxy
    require profile::mediawiki::common
    require profile::mediawiki::nutcracker
    class { 'profile::mediawiki::mcrouter_wancache':
        prometheus_exporter => false
    }
    require profile::services_proxy::envoy

    $xmldumpsmount = '/mnt/dumpsdata'

    class { '::dumpsuser': }

    if ($dumps_misc_cronrunner) {
        $nfs_server = $cron_nfs_server
    }
    else {
        $nfs_server = $dumps_nfs_server
    }
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
        systemdjobsdir     =>  "${xmldumpsmount}/otherdumps",
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
