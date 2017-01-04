class labstore::backup_keys {

    # Notice requires hiera addition at the moment:
    # Because we have a ssh::userkey stanza
    # and it will not be used without this hack.  Same pattern ganeti uses.
    # ssh::server::authorized_keys_file: /etc/ssh/userkeys/%u /etc/ssh/userkeys/%u.d/cumin /etc/ssh/userkeys/%u.d/labstore

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
