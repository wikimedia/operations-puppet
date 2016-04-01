class snapshot::addschanges::config(
    $enable = true,
) {

    include snapshot::dumps::dirs

    $confsdir = ${snapshot::dumps::dirs::addschangesdir}/confs
    $dblistsdir = ${snapshot::dumps::dirs::addschangesdir}/dblists

    if ($enable) {
        file { $confsdir:
            ensure => 'directory',
            path   => $confsdir,
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        file { "${confsdir}/addschanges.conf":
            ensure  => 'present',
            path    => "${confsdir}/addschanges.conf",
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            content => template('snapshot/addschanges.conf.erb'),
        }
        file { $dblistsdir:
            ensure => 'directory',
            path   => dblistsdir,
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        $skipdbs = ['labswiki','labtestwiki']
        $skipdbs_dblist = join($skipdbs, "\n")
        file { "${dblistsdir}/dblists/skip.dblist":
            ensure  => 'present',
            path    => "${dblistsdir}/skip.dblist",
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            content => "${skipdbs_dblist}\n",
        }
    }
}
