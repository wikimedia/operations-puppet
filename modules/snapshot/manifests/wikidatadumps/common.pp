class snapshot::wikidatadumps::common {
    file { '/usr/local/bin/wikidatadumps-shared.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/wikidatadumps-shared.sh',
    }

    file { '/var/log/wikidatadump':
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'www-data',
    }

    file { '/usr/local/share/dcat':
        ensure  => 'directory',
        mode    => '0444',
        owner   => 'datasets',
        group   => 'www-data',
        recurse => true,
        purge   => true,
        source  => 'puppet:///modules/snapshot/dcat',
    }
}

