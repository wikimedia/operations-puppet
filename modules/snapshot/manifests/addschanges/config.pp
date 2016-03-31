class snapshot::addschanges::config(
    $enable = true,
) {

    include snapshot::dumps::dirs

    if ($enable) {
        file { "${snapshot::dumps::dirs::addschangesdir}/confs":
            ensure => 'directory',
            path   => "${snapshot::dumps::dirs::addschangesdir}/confs",
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        file { "${snapshot::dumps::dirs::addschangesdir}/confs/addschanges.conf":
            ensure  => 'present',
            path    => "${snapshot::dumps::dirs::addschangesdir}/confs/addschanges.conf",
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            content => template('snapshot/addschanges.conf.erb'),
        }
        file { "${snapshot::dumps::dirs::addschangesdir}/dblists":
            ensure => 'directory',
            path   => "${snapshot::dumps::dirs::addschangesdir}/dblists",
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        $skipdbs = ['labswiki','labtestwiki']
        $skipdbs_dblist = join($skipdbs, "\n")
        file { "${snapshot::dumps::dirs::addschangesdir}/dblists/skip.dblist":
            ensure  => 'present',
            path    => "${snapshot::dumps::dirs::addschangesdir}/dblists/skip.dblist",
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            content => "${skipdbs_dblist}\n",
        }
    }
}
