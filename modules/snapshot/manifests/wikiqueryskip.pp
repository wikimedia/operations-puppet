class snapshot::wikiqueryskip {
    include snapshot::dirs

    file { "${snapshot::dirs::wikiqueriesdir}/dblists":
        ensure => 'directory',
        path   => "${snapshot::dirs::wikiqueriesdir}/dblists",
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    $skipdbs = ['labswiki','labtestwiki']
    $skipdbs_dblist = join($skipdbs, "\n")
    file { "${snapshot::dirs::wikiqueriesdir}/dblists/skip.dblist":
        ensure  => 'present',
        path    => "${snapshot::dirs::wikiqueriesdir}/dblists/skip.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${skipdbs_dblist}\n",
    }
}
