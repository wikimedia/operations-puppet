define snapshot::dumps::stagesconf(
    $stagestype = 'normal',
    $stages     = undef,
    ) {

    include snapshot::dirs

    file { "${snapshot::dirs::dumpsdir}/stages/${title}":
        ensure  => 'present',
        path    => "${snapshot::dirs::dumpsdir}/stages/${title}",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/dumpstages.erb'),
    }
}
