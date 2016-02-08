class snapshot::mediaperprojectlists(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dirs

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/local/bin/create-media-per-project-lists.sh':
        ensure  => 'present',
        path    => '/usr/local/bin/create-media-per-project-lists.sh',
        mode    => '0755',
        owner   => $user,
        group   => root,
        content => template('snapshot/create-media-per-project-lists.sh.erb'),
    }

    file { "${snapshot::dirs::wikiqueriesdir}/confs/wq.conf.media":
        ensure  => 'present',
        path    => "${snapshot::dirs::wikiqueriesdir}/confs/wq.conf.media",
        mode    => '0644',
        owner   => $user,
        group   => root,
        content => template('snapshot/wq.conf.media.erb'),
    }

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

    cron { 'list-media-per-project':
        ensure      => $ensure,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => '/usr/local/bin/create-media-per-project-lists.sh',
        minute      => '10',
        hour        => '11',
        weekday     => '7',
    }
}
