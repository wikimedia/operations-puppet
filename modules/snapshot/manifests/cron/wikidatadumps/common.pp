class snapshot::cron::wikidatadumps::common {
    file { '/usr/local/bin/wikidatadumps-shared.sh':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/wikidatadumps-shared.sh.erb'),
    }

    file { '/var/log/wikidatadump':
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'www-data',
    }

    git::clone { 'DCAT-AP':
        ensure    => 'present', # Don't automatically update.
        directory => '/usr/local/share/dcat',
        origin    => 'https://gerrit.wikimedia.org/r/operations/dumps/dcat',
        branch    => 'master',
        owner     => 'datasets',
        group     => 'www-data',
    }

    file { '/usr/local/etc/dcatconfig.json':
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dcatconfig.json',
    }
}

