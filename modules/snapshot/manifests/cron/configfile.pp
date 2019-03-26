define snapshot::cron::configfile(
    $configvals = undef,
    ) {
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { "${confsdir}/${title}":
        ensure  => 'present',
        path    => "${confsdir}/${title}",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/wikidump.conf.other.erb'),
    }
}
