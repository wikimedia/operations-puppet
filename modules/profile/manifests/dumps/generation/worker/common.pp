class profile::dumps::generation::worker::common {
    # mw packages and dependencies
    require ::profile::mediawiki::scap_proxy
    require ::profile::mediawiki::common
    require ::profile::mediawiki::nutcracker

    $xmldumpsmount = '/mnt/dumpsdata'
    $miscdumpsmount = '/mnt/data'

    class { '::dumpsuser': }

    snapshot::dumps::nfsmount { 'dumpsdatamount':
        mountpoint => $xmldumpsmount,
        server     => 'dumpsdata1001.eqiad.wmnet',
    }
    snapshot::dumps::nfsmount { 'datasetmount':
        mountpoint => $miscdumpsmount,
        server     => 'dataset1001.wikimedia.org',
    }

    # dataset server config files,
    # stages files, dblists, html templates
    class { '::snapshot::dumps::dirs':
        user           => 'dumpsgen',
        xmldumpsmount  => $xmldumpsmount,
        miscdumpsmount => $miscdumpsmount,
    }
    class { '::snapshot::dumps':
        xmldumpsmount  => $xmldumpsmount,
        miscdumpsmount => $miscdumpsmount,
    }

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
