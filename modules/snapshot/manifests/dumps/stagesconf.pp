define snapshot::dumps::stagesconf(
    $stagestype = 'full',
    $stages     = undef,
    ) {
    $stagesdir = $snapshot::dumps::dirs::stagesdir

    file { "${stagesdir}/${title}":
        ensure  => 'present',
        path    => "${stagesdir}/${title}",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/dumps/dumpstages.erb'),
    }
}
