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

    file { "${snapshot::dumps::dirs::dumpsdir}/fulldumps.sh":
        ensure  => 'present',
        path    => "${snapshot::dumps::dirs::dumpsdir}/fulldumps.sh",
        mode    => '0755',
        owner   => $user,
        group   => root,
        content => template('snapshot/fulldumps.sh.erb'),
    }
}
