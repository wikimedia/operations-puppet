# = Class: labstore::replica_users
# Creates replica.my.cnf files for users to allow
# access to the mysql replica labsdbs
class labstore::replica_users {
    require_package( 'libclass-dbi-mysql-perl' )

    file { '/usr/local/sbin/replica-addusers.pl':
        source => 'puppet:///modules/labstore/replica-addusers.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    file { '/etc/init/replica-addusers.conf':
        source  => 'puppet:///modules/labstore/replica-addusers.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/local/sbin/replica-addusers.pl'],
    }

    # There is no service {} stanza on purpose -- this service
    # must *only* be started by a manual operation because it must
    # run exactly once on whichever NFS server is the current
    # active one.
}
