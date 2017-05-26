class ca::manager {
    # keytool dependency
    require_package('default-jre')

    file { '/usr/local/bin/ca-manager':
        source => 'puppet:///modules/ca/ca-manager',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
