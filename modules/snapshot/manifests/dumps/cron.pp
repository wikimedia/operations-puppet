class snapshot::dumps::cron(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dirs

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/srv/dumps/fulldumps.sh':
        ensure  => 'present',
        path    => '/srv/dumps/fulldumps.sh',
        mode    => '0755',
        owner   => $user,
        group   => root,
        content => template('snapshot/fulldumps.sh.erb'),
    }
}
