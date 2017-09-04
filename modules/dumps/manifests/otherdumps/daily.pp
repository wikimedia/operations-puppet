class dumps::otherdumps::daily (
    $user = undef,
    $confsdir = undef,
    $repodir = undef,
    $otherdumpsdir = undef,
)  {
    include dumps:otherdumps::daily::mediaperprojectlists

    file { '/usr/local/bin/otherdumps-dailies.sh':
        ensure => 'present',
        path   => '/usr/local/bin/otherdumps-dailies.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/otherdumps/dailies.sh',
    }

    cron { 'otherdumps-dailies':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "/usr/local/bin/otherdumps-dailies.sh --confsdir $confsdir --repodir $repodir --otherdumpsdir $otherdumpsdir",
        minute      => '10',
        hour        => '6',
        weekday     => '0',
        require     => File['/usr/local/bin/otherdumps-dailies.sh'],
    }

}
