define snapshot::dumps::stagesconf(
    $stagestype = 'normal',
    $stages     = undef,
    ) {

    include snapshot::dumps::dirs

    file { "${snapshot::dumps::dirs::dumpsdir}/stages/${title}":
        ensure  => 'present',
        path    => "${snapshot::dumps::dirs::dumpsdir}/stages/${title}",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/dumps/dumpstages.erb'),
    }
}
