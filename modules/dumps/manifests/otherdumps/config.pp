class dumps::otherdumps::config (
    $confsdir = undef,
    $dumpdatadir = undef,
    $apachedir = undef,
) {
    file { "${confsdir}":
        ensure  => 'directory',
        path    => "${confsdir}/otherdumps.conf",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }
    file { "${confsdir}/otherdumps.conf":
        ensure  => 'present',
        path    => "${confsdir}/otherdumps.conf",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/otherdumps/otherdumps.conf.erb'),
    }
}
