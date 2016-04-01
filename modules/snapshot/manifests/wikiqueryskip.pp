class snapshot::wikiqueryskip {
    include snapshot::dumps::dirs
    $dblistsdir = "${snapshot::dumps::dirs::wikiqueriesdir}/dblists"
    file { $dblistsdir:
        ensure => 'directory',
        path   => $dblistsdir,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    $skipdbs = ['labswiki','labtestwiki']
    $skipdbs_dblist = join($skipdbs, "\n")
    file { "${dblistsdir}/dblists/skip.dblist":
        ensure  => 'present',
        path    => "${dblistsdir}/dblists/skip.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${skipdbs_dblist}\n",
    }
}
