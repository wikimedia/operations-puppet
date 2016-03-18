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

    $keep_generator=['categoriesrdf:3', 'categoriesrdf/daily:3', 'cirrussearch:3', 'contenttranslation:3', 'globalblocks:3', 'imageinfo:3', 'mediatitles:3', 'pagetitles:3', 'shorturls:3', 'wikibase/wikidatawiki:3']
    $keep_replicas=['categoriesrdf:11', 'categoriesrdf/daily:15', 'cirrussearch:11', 'contenttranslation:14', 'globalblocks:13', 'imageinfo:32', 'mediatitles:90', 'pagetitles:90', 'shorturls:7', 'wikibase/wikidatawiki:20']
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

    # adds-changes dumps cleanup; these are in incr/wikiname/YYYYMMDD for each day, so they can't go into the above config/cron setup
    $cleanup_addschanges = "find ${miscdumpsdir}/incr -mindepth 2 -maxdepth 2 -type d -mtime +${addschanges_keeps} -exec rm -rf {} \\;"

    cron { 'cleanup-misc-dumps':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "${cleanup_miscdumps} ; ${cleanup_addschanges}",
        user        => root,
        minute      => '15',
        hour        => '7',
        require     => File['/usr/local/bin/cleanup_old_miscdumps.sh'],
    }
}
