class snapshot::dumps::mediadirlists (
    $enable = true,
    $user   = undef,
) {
    include snapshot::dumps::dirs
    include snapshot::wikiqueryskip

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/local/bin/runphpscriptletonallwikis.py':
        ensure => 'present',
        path   => '/usr/local/bin/runphpscriptletonallwikis.py',
        mode   => '0755',
        owner  => $user,
        group  => root,
        source => 'puppet:///modules/snapshot/runphpscriptletonallwikis.py',
    }

    file { '/usr/local/bin/listwikiuploaddirs.py':
        ensure => 'present',
        path   => '/usr/local/bin/listwikiuploaddirs.py',
        mode   => '0755',
        owner  => $user,
        group  => root,
        source => 'puppet:///modules/snapshot/listwikiuploaddirs.py',
    }

    file { '/usr/local/bin/create-mediadir-list.sh':
        ensure  => 'present',
        path    => '/usr/local/bin/create-mediadir-list.sh',
        mode    => '0755',
        owner   => $user,
        group   => root,
        content => template('snapshot/create-mediadir-list.sh.erb'),
    }

    cron { 'list-media-dirs':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => '/usr/local/bin/create-mediadir-list.sh',
        minute      => '10',
        hour        => '2',
    }
}
