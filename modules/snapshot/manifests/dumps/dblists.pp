class snapshot::dumps::dblists($enable=true, $hugewikis_enable=false) {
    if ($enable) {
        $hugewikis = ['enwiki']
        $hugewikis_dblist = join($hugewikis, "\n")

        $bigwikis = ['dewiki', 'eswiki', 'frwiki', 'itwiki', 'jawiki',
                    'metawiki', 'nlwiki', 'plwiki', 'ptwiki', 'ruwiki', 'commonswiki',
                    'wikidatawiki', 'zhwiki']
        $bigwikis_dblist = join($bigwikis, "\n")

        # labswiki Broken, DB permissions issues?
        $excludewikis = ['labswiki']
        $excludewikis_dblist = join($excludewikis, "\n")

        $skip_dblist = "${hugewikis_dblist}\n${bigwikis_dblist}\n${excludewikis_dblist}"

        $skipnone_dblist = ''

        $globalusage_dblist = 'commonswiki'

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
        file { "${snapshot::dirs::dumpsdir}/dblists/skipmonitor.dblist":
            ensure  => 'present',
            path    => "${snapshot::dirs::dumpsdir}/dblists/skipmonitor.dblist",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${excludewikis_dblist}\n",
        }
        file { "${snapshot::dirs::dumpsdir}/dblists/skipnone.dblist":
            ensure  => 'present',
            path    => "${snapshot::dirs::dumpsdir}/dblists/skipnone.dblist",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${skipnone_dblist}\n",
        }
        file { "${snapshot::dirs::dumpsdir}/dblists/globalusage.dblist":
            ensure  => 'present',
            path    => "${snapshot::dirs::dumpsdir}/dblists/globalusage.dblist",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${globalusage_dblist}\n",
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
