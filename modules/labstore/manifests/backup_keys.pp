class labstore::backup_keys {

    # Labstores need to be able to scp from one server
    # to the other (in order to do backups)
    ssh::userkey { 'root-labstore':
        ensure => present,
        user   => 'root',
        skey   => 'labstore',
        source => 'puppet:///modules/labstore/id_labstore.pub',
    }

    file { '/root/.ssh/id_labstore':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => secret('labstore/id_labstore'),
    }
}
