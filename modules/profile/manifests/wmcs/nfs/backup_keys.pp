class profile::wmcs::nfs::backup_keys {

    # Allow cloudstores to scp from each other for backups
    ssh::userkey { 'root-cloudstore':
        ensure => present,
        user   => 'root',
        skey   => 'cloudstore',
        source => 'puppet:///modules/profile/wmcs/nfs/id_cloudstore.pub',
    }

    file { '/root/.ssh/id_cloudstore':
        ensure    => present,
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        content   => secret('cloudstore/id_cloudstore'),
        show_diff => false,
    }
}
