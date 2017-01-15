class snapshot::dumps::dblists {
    $hugewikis = ['enwiki']
    $hugewikis_dblist = join($hugewikis, "\n")

    $bigwikis = ['dewiki', 'eswiki', 'frwiki', 'itwiki', 'jawiki',
                'metawiki', 'nlwiki', 'plwiki', 'ptwiki', 'ruwiki', 'commonswiki',
                'wikidatawiki', 'zhwiki']
    $bigwikis_dblist = join($bigwikis, "\n")

    # labswiki(s) can't be dumped from snapshot hosts
    $excludewikis = ['labswiki', 'labtestwiki']
    $excludewikis_dblist = join($excludewikis, "\n")

    $skip_dblist = "${hugewikis_dblist}\n${bigwikis_dblist}\n${excludewikis_dblist}"

    $skipnone_dblist = ''

    $globalusage_dblist = 'commonswiki'

    include ::snapshot::dumps::dirs

    $dblistsdir = $snapshot::dumps::dirs::dblistsdir

    file { "${dblistsdir}/hugewikis.dblist":
        ensure  => 'present',
        path    => "${dblistsdir}/hugewikis.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${hugewikis_dblist}\n",
    }
    file { "${dblistsdir}/bigwikis.dblist":
        ensure  => 'present',
        path    => "${dblistsdir}/bigwikis.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${bigwikis_dblist}\n",
    }
    file { "${dblistsdir}/skip.dblist":
        ensure  => 'present',
        path    => "${dblistsdir}/skip.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${skip_dblist}\n",
    }
    file { "${dblistsdir}/skipmonitor.dblist":
        ensure  => 'present',
        path    => "${dblistsdir}/skipmonitor.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${excludewikis_dblist}\n",
    }
    file { "${dblistsdir}/skipnone.dblist":
        ensure  => 'present',
        path    => "${dblistsdir}/skipnone.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${skipnone_dblist}\n",
    }
    file { "${dblistsdir}/globalusage.dblist":
        ensure  => 'present',
        path    => "${dblistsdir}/globalusage.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${globalusage_dblist}\n",
    }

    $warning = "The files in this directory are maintained by puppet!\n"
    $location = "puppet:///modules/snapshot/dumps/dblists.pp\n"

    file { "${dblistsdir}/README":
        ensure  => 'present',
        path    => "${dblistsdir}/README",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${warning}${location}",
    }
}
