class snapshot::dumps::dblists($enable=true, $hugewikis_enable=false) {
    if ($enable) {
        $hugewikis = ['enwiki']
        $hugewikis_dblist = join($hugewikis, "\n")

        $bigwikis = ['dewiki', 'eswiki', 'frwiki', 'itwiki', 'jawiki',
                    'nlwiki', 'plwiki', 'ptwiki', 'ruwiki']
        $bigwikis_dblist = join($bigwikis, "\n")

        # Broken, DB permissions issues?
        $excludewikis = ['labswiki']
        $excludewikis_dblist = join($excludewikis, "\n")

        $skip_dblist = "${hugewikis_dblist}\n${bigwikis_dblist}\n${excludewikis_dblist}"

        $skipnone_dblist = ''

        include snapshot::dirs

        file { "${snapshot::dirs::dumpsdir}/dblists":
            ensure => 'directory',
            path   => "${snapshot::dirs::dumpsdir}/dblists",
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        if ($hugewikis_enable) {
            # this host will run enwiki dumps
            file { "${snapshot::dirs::dumpsdir}/dblists/hugewikis.dblist":
                ensure  => 'present',
                path    => "${snapshot::dirs::dumpsdir}/dblists/hugewikis.dblist",
                mode    => '0644',
                owner   => 'root',
                group   => 'root',
                content => "${hugewikis_dblist}\n",
            }
        }
        file { "${snapshot::dirs::dumpsdir}/dblists/bigwikis.dblist":
            ensure  => 'present',
            path    => "${snapshot::dirs::dumpsdir}/dblists/bigwikis.dblist",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${bigwikis_dblist}\n",
        }
        file { "${snapshot::dirs::dumpsdir}/dblists/skip.dblist":
            ensure  => 'present',
            path    => "${snapshot::dirs::dumpsdir}/dblists/skip.dblist",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${skip_dblist}\n",
        }
        file { "${snapshot::dirs::dumpsdir}/dblists/skipnone.dblist":
            ensure  => 'present',
            path    => "${snapshot::dirs::dumpsdir}/dblists/skipnone.dblist",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${skipnone_dblist}\n",
        }

        $warning = "The files in this directory are maintained by puppet!\n"
        $location = "puppet:///modules/snapshot/dumps/dblists.pp\n"

        file { "${snapshot::dirs::dumpsdir}/dblists/README":
            ensure  => 'present',
            path    => "${snapshot::dirs::dumpsdir}/dblists/README",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${warning}${location}",
        }
    }
}
