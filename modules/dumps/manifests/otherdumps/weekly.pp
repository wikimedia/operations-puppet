class dumps::otherdumps::weekly(
    $user = undef,
    $confsdir = undef,
    $repodir = undef,
    $otherdumpsdir = undef,
) {
    class {'::dumps::otherdumps::weekly::categoriesrdf':
        user => $user,
    }
    class {'::dumps::otherdumps::weekly::cirrussearch':
        user => $user,
    }
    class {'::dumps::otherdumps::weekly::contentxlation':
        user => $user,
    }
    class {'::dumps::otherumps::weekly::globalblocks':
        user => $user,
    }
    class {'::dumps::otherdumps::weekly::mediaperprojectlists':
        user => $user,
    }

    file { '/usr/local/bin/otherdumps-weeklies.sh':
        ensure  => 'present',
        path    => '/usr/local/bin/otherdumps-weeklies.sh',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dumps/otherdumps/otherdumps-weeklies.sh',
        require => Class[':dumpscrons::weekly::categoriesrdf',
                         '::dumpscrons::weekly::cirrussearch',
                         '::dumpscrons::weekly::contentxlation',
                         '::dumpscrons::weekly::globalblocks',
                         '::dumpscrons::weekly::mediaperprojectlists'],
    }

    cron { 'otherdumps-weeklies':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => '/usr/local/bin/otherdumps-weeklies.sh --confsdir $confsdir --repodir $repodir --otherdumpsdir $otherdumpsdir',
        minute      => '10',
        hour        => '6',
        weekday     => '0',
        require     => File['/usr/local/bin/otherdumps-weeklies.sh'],
    }

}
