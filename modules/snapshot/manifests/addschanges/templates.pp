class snapshot::addschanges::templates($enable=true) {
    if ($enable) {

        include snapshot::dumps::dirs

        file { "${snapshot::dumps::dirs::addschangesdir}/templs":
            ensure => 'directory',
            path   => "${snapshot::dumps::dirs::addschangesdir}/templs",
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        file { "${snapshot::dumps::dirs::addschangesdir}/templs/incrs-index.html":
            ensure => 'present',
            path   => "${snapshot::dumps::dirs::addschangesdir}/templs/incrs-index.html",
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/snapshot/addschanges/incrs-index.html',
        }
        $warning = "The files in this directory are maintained by puppet!\n"
        $location = "puppet:///modules/snapshot/dumps/addschanges/templates\n"

        file { "${snapshot::dumps::dirs::addschangesdir}/templs/README":
            ensure  => 'present',
            path    => "${snapshot::dumps::dirs::addschangesdir}/templs/README",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${warning}${location}",
        }
    }
}
