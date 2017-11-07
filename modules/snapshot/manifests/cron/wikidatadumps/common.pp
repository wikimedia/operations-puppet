class snapshot::cron::wikidatadumps::common(
    $user = undef,
    $group = undef,
)  {
    file { '/usr/local/bin/wikidatadumps-shared.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/wikidatadumps-shared.sh',
    }

    file { '/var/log/wikidatadump':
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    git::clone { 'DCAT-AP':
        ensure    => 'present', # Don't automatically update.
        directory => '/usr/local/share/dcat',
        origin    => 'https://gerrit.wikimedia.org/r/operations/dumps/dcat',
        branch    => 'master',
        owner     => $user,
        group     => $group,
    }

    file { '/usr/local/etc/dcatconfig.json':
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dcatconfig.json',
    }
}

