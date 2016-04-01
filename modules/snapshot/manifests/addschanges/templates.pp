class snapshot::addschanges::templates($enable=true) {
    if ($enable) {

        include snapshot::dumps::dirs
        $templsdir = "${snapshot::dumps::dirs::addschangesdir}/templs"

        file { $templsdir:
            ensure => 'directory',
            path   => $templsdir,
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        file { "${templsdir}/incrs-index.html":
            ensure => 'present',
            path   => "${templsdir}/incrs-index.html",
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/snapshot/addschanges/incrs-index.html',
        }
        $warning = "The files in this directory are maintained by puppet!\n"
        $location = "puppet:///modules/snapshot/dumps/addschanges/templates\n"

        file { "${templsdir}/README":
            ensure  => 'present',
            path    => "${templsdir}/README",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${warning}${location}",
        }
    }
}
