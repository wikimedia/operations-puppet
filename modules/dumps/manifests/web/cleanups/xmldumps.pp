class dumps::web::cleanups::xmldumps(
    $wikilist_url = undef,
    $publicdir = undef,
    $user = undef,
) {
    $wikilist_dir = '/etc/dumps/dblists'
    file { $wikilist_dir:
        ensure => 'directory',
        path   => $wikilist_dir,
        mode   => '0755',
        owner  => $user,
        group  => 'root',
    }

    # these lists are used only to decide how many dumps of
    # each type of wiki we keep.
    $bigwikis = ['dewiki', 'eswiki', 'frwiki', 'itwiki', 'jawiki',
                  'metawiki', 'nlwiki', 'plwiki', 'ptwiki', 'ruwiki',
                  'commonswiki', 'wikidatawiki', 'zhwiki']
    $bigwikis_dblist = join($bigwikis, "\n")

    $hugewikis = ['enwiki', 'wikidatawiki']
    $hugewikis_dblist = join($hugewikis, "\n")

    file { "${wikilist_dir}/hugewikis.dblist":
        ensure  => 'present',
        path    => "${wikilist_dir}/hugewikis.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${hugewikis_dblist}\n",
    }

    file { "${wikilist_dir}/bigwikis.dblist":
        ensure  => 'present',
        path    => "${wikilist_dir}/bigwikis.dblist",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${bigwikis_dblist}\n",
    }

    # how many dumps we keep of each type. in practice we keep one
    # less, so that when a new dump run starts and partial dumps are
    # copied over to the web server, space is available for that new
    # run BEFORE it is copied.
    $keeps = ['hugewikis.dblist:7', 'bigwikis.dblist:8', 'default:10']
    $keeps_content = join($keeps, "\n")

    file { '/etc/dumps/xml_keeps.conf':
        ensure  => 'present',
        path    => '/etc/dumps/xml_keeps.conf',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${keeps_content}\n",
    }

    file { '/usr/local/bin/cleanup_old_xmldumps.py':
        ensure => 'present',
        path   => '/usr/local/bin/cleanup_old_xmldumps.py',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/cleanups/cleanup_old_xmldumps.py',
    }

    $command = '/usr/bin/python /usr/local/bin/cleanup_old_xmldumps.py'
    $args = "-d ${publicdir} -w ${wikilist_dir} -k /etc/dumps/xml_keeps.conf"

    cron { 'cleanup_xmldumps':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "${command} ${args}",
        user        => $user,
        minute      => '25',
        hour        => '1',
        require     => File['/usr/local/bin/cleanup_old_xmldumps.py'],
    }

}
