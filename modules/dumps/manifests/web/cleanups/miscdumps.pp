class dumps::web::cleanups::miscdumps(
    $miscdumpsdir = undef,
) {
    file { '/usr/local/bin/cleanup_old_miscdumps.sh':
        ensure => 'directory',
        path   => '/usr/local/bin/cleanup_old_miscdumps.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/cleanups/cleanup_old_miscdumps.sh',
    }

    # each entry is subdir:N, to keep the newest N runs; subdir may be a glob
    $keep_runs=['categoriesrdf:11', 'categoriesrdf/daily:15', 'cirrussearch:11', 'contenttranslation:14', 'enterprise_html/runs:6', 'growthmentorship:13', 'imageinfo:32', 'machinevision:13', 'mediatitles:90', 'mediawiki_content_current/*:6', 'mediawiki_content_history/*:6', 'pagetitles:90', 'shorturls:7', 'wikibase/wikidatawiki:20', 'wikibase/commonswiki:20']
    $content = join($keep_runs, "\n")

    file { '/etc/dumps/confs/cleanup_misc.conf':
        ensure  => 'present',
        path    => '/etc/dumps/confs/cleanup_misc.conf',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => "${content}\n"
    }

    $cleanup_miscdumps = "/bin/bash /usr/local/bin/cleanup_old_miscdumps.sh --miscdumpsdir ${miscdumpsdir} --configfile /etc/dumps/confs/cleanup_misc.conf"

    # adds-changes dumps cleanup; these are in incr/wikiname/YYYYMMDD for each day, so they can't go into the above config setup
    $cleanup_addschanges = "/usr/bin/find ${miscdumpsdir}/incr -mindepth 2 -maxdepth 2 -type d -mtime +40 -exec rm -rf {} \\;"
    systemd::timer::job { 'cleanup-misc-dumps':
        ensure             => present,
        description        => 'Regular jobs to clean up misc dumps',
        user               => root,
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => $cleanup_miscdumps,
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 7:15:0'},
        require            => File['/usr/local/bin/cleanup_old_miscdumps.sh'],
    }

    systemd::timer::job { 'cleanup-addschanges':
        ensure             => present,
        description        => 'Regular jobs to clean up adds-changes dumps',
        user               => root,
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => $cleanup_addschanges,
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 8:15:0'},
    }
}
