class snapshot::dumps::cron(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dumps::dirs

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { "/usr/local/bin/fulldumps.sh":
        ensure  => 'present',
        path    => "/usr/local/bin/fulldumps.sh",
        mode    => '0755',
        owner   => $user,
        group   => root,
        content => template('snapshot/fulldumps.sh.erb'),
    }
}
