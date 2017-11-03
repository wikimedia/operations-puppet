class dumps::web::cleanups::xml_cleanup(
    $wikilist_url = undef,
    $wikilist_dir = undef,
    $publicdir = undef,
    $user = undef,
) {
    file { '/etc/dumps':
        ensure => 'directory',
        path   => '/etc/dumps',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

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
    # Some wikis in the allwikis list may be also in one of the
    # other lists. That's fine, the smaller number to keep always wins.
    $keeps = ['hugewikis.dblist:6', 'bigwikis.dblist:7', 'allwikis.dblist:9']
    $keeps_content = join($keeps, "\n")

    file { '/etc/dumps/xml_keeps.conf':
        ensure  => 'present',
        path    => '/etc/dumps/xml_keeps.conf',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${keeps_content}\n",
    }

    # get and save the list of all wikis.
    # private or nonexistent wikis can be skipped by the cleanup script so
    # we don't filter the list here.
    $curl_command = '/usr/bin/curl --connect-timeout 5 -s --retry 5 --retry-delay 10'
    $curl_output = "${wikilist_dir}/allwikis.dblist"
    $curl_args = "-z ${curl_output} -o ${curl_output} '${wikilist_url}'"

    cron { 'get_wiki_list':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "${curl_command} ${curl_args}",
        user        => $user,
        minute      => '20',
        hour        => '1',
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
