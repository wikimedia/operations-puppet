class dumps::web::cleanups::xmldumps(
    $xmldumpsdir = undef,
    $dumpstempdir = undef,
    $user = undef,
    $isreplica = undef,
) {
    $wikilist_dir = '/etc/dumps/dblists'
    file { $wikilist_dir:
        ensure => 'directory',
        path   => $wikilist_dir,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # these lists are used only to decide how many dumps of
    # each type of wiki we keep.
    $bigwikis = ['dewiki', 'eswiki', 'frwiki', 'itwiki', 'jawiki',
                  'metawiki', 'nlwiki', 'plwiki', 'ptwiki', 'ruwiki',
                  'commonswiki', 'svwiki', 'zhwiki', 'kowiki']
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

    # on generator nfs hosts we must keep a minimum of 3 so that at any time
    # we have at least one old full dump around, with all revision content
    # which can be stolen from for the next dump run.  This is due to
    # the way we run dumps: one full run, then one run without full
    # revision content, etc.
    # we would like to keep partials of 2 dumps, for prefetch purposes,
    # just in case there's an issue with the last full run. This is most important
    # for the small wikis, for which we don't generate page dumps in small pieces
    # and so broken prefetch files mean pulling all historical revision content
    # directly from the database.

    $keep_generator = ['hugewikis.dblist:3:1', 'bigwikis.dblist:3:1', 'default:3:1']
    $keep_replicas = ['hugewikis.dblist:7', 'bigwikis.dblist:8', 'default:10']

    if ($isreplica == true) {
        $content= join($keep_replicas, "\n")
    } else {
        $content= join($keep_generator, "\n")
    }

    file { '/etc/dumps/xml_keeps.conf':
        ensure  => 'present',
        path    => '/etc/dumps/xml_keeps.conf',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => "${content}\n",
    }

    # set up the file containing expressions to match dump output
    # files we need to keep around, for those dumps we don't remove
    # completely, on the dumps generator nfs hosts.
    if ($isreplica == false) {
        $patternslist = ['.*-pages-articles[0-9]*.xml.*(bz2|7z)',
                        '.*-pages-meta-current[0-9]*.xml.*(bz2|7z)',
                        '.*-pages-meta-history[0-9]*.xml.*(bz2|7z)',
                        '.*-flowhistory.xml.gz',
                        '.*dumpruninfo.txt']
        $patterns= join($patternslist, "\n")
        $patternsfile = '/etc/dumps/xml_keep_patterns.conf'
        file { $patternsfile:
            ensure  => 'present',
            path    => $patternsfile,
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => "${patterns}\n",
        }
    }

    file { '/usr/local/bin/cleanup_old_xmldumps.py':
        ensure => 'present',
        path   => '/usr/local/bin/cleanup_old_xmldumps.py',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/cleanups/cleanup_old_xmldumps.py',
    }

    $xmlclean = '/usr/bin/python3 /usr/local/bin/cleanup_old_xmldumps.py'
    $args = "-d ${xmldumpsdir} -w ${wikilist_dir} -k /etc/dumps/xml_keeps.conf"

    if ($isreplica == false) {
        # the temp dir only exists on the generating hosts (nfs servers),
        # so only clean up temp files there
        $tempclean = "/usr/bin/find ${dumpstempdir} -type f -mtime +20 -exec rm {} \\;"
        systemd::timer::job { 'cleanup_tmpdumps':
            ensure             => present,
            description        => 'Regular jobs to clean up tmp dumps',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => $tempclean,
            interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 2:25:0'},
            require            => File['/usr/local/bin/cleanup_old_xmldumps.py'],
        }
        # patternsfile has patterns that match dump output files we want to keep,
        # for dump runs we don't want to remove completely, on the dumps generator nfs hosts
        $job_command = "${xmlclean} ${args} -p ${patternsfile}"
    } else {
        $job_command = "${xmlclean} ${args}"
    }
    systemd::timer::job { 'cleanup_xmldumps':
        ensure             => present,
        description        => 'Regular jobs to clean up xml dumps',
        user               => $user,
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => $job_command,
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 9:25:0'},
        require            => File['/usr/local/bin/cleanup_old_xmldumps.py'],
    }
}
