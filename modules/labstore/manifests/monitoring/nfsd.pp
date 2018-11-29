class labstore::monitoring::nfsd {

    diamond::collector { 'NfsdCollector':
        ensure => 'absent'
    }
}
