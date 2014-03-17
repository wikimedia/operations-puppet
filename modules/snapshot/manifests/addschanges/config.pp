class snapshot::addschanges::config(
    $enable = true,
) {

    include snapshot::dirs

    if ($enable) {
        file { "${snapshot::dirs::addschangesdir}/confs":
            ensure => 'directory',
            path   => "${snapshot::dirs::addschangesdir}/confs",
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        file { "${snapshot::dirs::addschangesdir}/confs/addschanges.conf":
            ensure  => 'present',
            path    => "${snapshot::dirs::addschangesdir}/confs/addschanges.conf",
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            content => template('snapshot/addschanges.conf.erb'),
        }
    }
}
