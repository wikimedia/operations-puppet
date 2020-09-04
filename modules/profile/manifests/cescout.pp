class profile::cescout (
    Stdlib::Unixpath $metadb_dir       = lookup('profile::cescout::postgres::metadb_dir'),
    String           $postgres_version = lookup('profile::cescout::postgres::version'),
    String           $http_proxy       = lookup('http_proxy'),
) {

    require_package('cescout')

    # required by metadb_s3_tarx
    require_package('make', 'bc')

    # for the specific version of postgres required, 9.6
    apt::package_from_component { 'thirdparty-postgres96':
        component => 'thirdparty/postgres96',
        packages  => ['postgresql-9.6']
    }

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
    file { $metadb_dir:
        ensure => 'directory',
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0700',
    }

    # copy the metadb_s3_tarx file, the script that sets up the metadb sync.
    file { '/usr/local/sbin/metadb_s3_tarx':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        content => template('cescout/metadb_s3_tarx.erb'),
    }

    # copy the metadb-configure.sh file, that calls metadb_s3_tarx and the
    # other scripts to finalize the sync process
    file { '/usr/local/sbin/metadb-configure':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        content => template('cescout/metadb-configure.sh.erb'),
    }

    systemd::tmpfile { 'postgresql':
        content => 'd /var/run/postgresql 0755 postgres postgres',
    }

    systemd::service { "postgresql@${postgres_version}-main.service":
        ensure   => present,
        override => true,
        restart  => true,
        content  => template('cescout/postgres-systemd-override.conf.erb'),
        require  => Package['postgresql-9.6'],
    }

}
