class puppet_compiler::legacy_local_database( $user, $vardir, ) {

    # Add a puppetdb instance with a local database.
    class { 'puppetdb::app':
        db_driver  => 'hsqldb',
        ca_path    => '/etc/puppetdb/ssl/ca.pem',
        db_rw_host => undef,
        perform_gc => true,
        bind_ip    => '0.0.0.0',
        ssldir     => "${vardir}/ssl",
        require    => Exec['Generate CA for the compiler']
    }

    file { '/etc/puppetdb/ssl/ca.pem':
        source => "${vardir}/ssl/certs/ca.pem",
        owner  => $user,
        before => Service['puppetdb']
    }

}
