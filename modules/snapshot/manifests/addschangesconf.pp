define snapshot::addschangesconf(
    $alldblist  = undef,
    ) {
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir
    $apachedir = $snapshot::dumps::dirs::apachedir
    $dblistsdir = $snapshot::dumps::dirs::dblistsdir
    $templsdir = $snapshot::dumps::dirs::templsdir
    $cronsdir = $snapshot::dumps::dirs::cronsdir

    file { "${confsdir}/${title}":
        ensure  => 'present',
        path    => "${confsdir}/${title}",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/addschanges.conf.erb'),
    }
}
