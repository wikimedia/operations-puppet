class dumps::web::cleanups::miscdumps(
    $isreplica = undef,
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

    # some datasets are pulled to replicas and not generated, so these lists don't
    # necessarily contain the same items. Note that 'replica' also includes
    # the dumpsdata fallback host(s), which will also not have any datasets pulled
    # directly to the public-facing (web/nfs) servers.
    $keep_generator=['categoriesrdf:3', 'categoriesrdf/daily:3', 'cirrussearch:2', 'contenttranslation:3', 'growthmentorship:3', 'imageinfo:3', 'machinevision:3', 'mediatitles:3', 'pagetitles:3', 'shorturls:3', 'wikibase/wikidatawiki:3', 'wikibase/commonswiki:3']
    $keep_replicas=['categoriesrdf:11', 'categoriesrdf/daily:15', 'cirrussearch:11', 'contenttranslation:14', 'enterprise_html/runs:6', 'growthmentorship:13', 'imageinfo:32', 'machinevision:13', 'mediatitles:90', 'pagetitles:90', 'shorturls:7', 'wikibase/wikidatawiki:20', 'wikibase/commonswiki:20']
    if ($isreplica == true) {
        $content= join($keep_replicas, "\n")
    } else {
        $content= join($keep_generator, "\n")
    }

    file { '/etc/dumps/confs/cleanup_misc.conf':
        ensure  => 'present',
        path    => '/etc/dumps/confs/cleanup_misc.conf',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => "${content}\n"
    }

    $cleanup_miscdumps = "/bin/bash /usr/local/bin/cleanup_old_miscdumps.sh --miscdumpsdir ${miscdumpsdir} --configfile /etc/dumps/confs/cleanup_misc.conf"

    if ($isreplica == true) {
        $addschanges_keeps = '40'
    } else {
        $addschanges_keeps = '7'
    }

    # adds-changes dumps cleanup; these are in incr/wikiname/YYYYMMDD for each day, so they can't go into the above config setup
    $cleanup_addschanges = "/usr/bin/find ${miscdumpsdir}/incr -mindepth 2 -maxdepth 2 -type d -mtime +${addschanges_keeps} -exec rm -rf {} \\;"
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
