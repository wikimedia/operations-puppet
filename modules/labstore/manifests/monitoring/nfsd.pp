class labstore::monitoring::nfsd {

    diamond::collector { 'NfsdCollector':
        source   => 'puppet:///modules/labstore/monitor/nfsd.py',
    }
}
