class profile::cescout {
    require_package('cescout')

    # required by metadb_s3_tarx
    require_package('make', 'bc')

    # enable system-wide proxy for cescout
    file { '/etc/profile.d/cescout.sh':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('cescout/cescout.sh.erb'),
    }

    # directory for saving metadb data. the OONI scripts use (and expect)
    # /mnt/metadb as they mount an EBS volume on EC2; since we don't do that,
    # we can use any directory and later point the metadb_s3_tarx to it.
    file { '/var/lib/metadb/':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # copy the metadb_s3_tarx file, the script that sets up the metadb sync.
    file { '/usr/local/sbin/metadb_s3_tarx':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        content => template('cescout/metadb_s3_tarx.erb'),
    }
}
