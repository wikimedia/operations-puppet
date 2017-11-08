class profile::dumps::generation::worker::common {
    # mw packages and dependencies
    require ::profile::mediawiki::scap_proxy
    require ::profile::mediawiki::common
    require ::profile::mediawiki::nutcracker

    class { '::dumpsuser': }
    class { '::dumps::deprecated::user': }

    snapshot::dumps::nfsmount { 'dumpsdatamount':
        mountpoint => '/mnt/dumpsdata',
        server     => 'dumpsdata1001.eqiad.wmnet',
    }
    snapshot::dumps::nfsmount { 'datasetmount':
        mountpoint => '/mnt/data',
        server     => 'dataset1001.wikimedia.org',
    }

    # dataset server config files,
    # stages files, dblists, html templates
    class { '::snapshot::dumps::dirs':
        user => 'dumpsgen',
    }
    class { '::snapshot::dumps':
        xmldumpsmount  => '/mnt/dumpsdata',
        miscdumpsmount => '/mnt/data',
    }

    # scap3 deployment of dump scripts
    scap::target { 'dumps/dumps':
        deploy_user => 'dumpsgen',
        manage_user => false,
        key_name    => 'dumpsdeploy',
    }
}
