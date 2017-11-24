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

    $keep_generator=['categories_rdf:3', 'cirrussearch:3', 'contentxlation:3', 'globalblocks:3', 'imageinfo:3', 'mediatitles:3', 'pagetitles:3', 'testfiles:3', 'wikibase/wikidatawiki:3']
    # FIXME set these to be the right numbers
    $keep_replicas=['categories_rdf:3', 'cirrussearch:3', 'contentxlation:3', 'globalblocks:3', 'imageinfo:3', 'mediatitles:3', 'pagetitles:3', 'testfiles:3', 'wikibase/wikidatawiki:3']
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

    cron { 'cleanup-misc-dumps':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "/bin/bash /usr/local/bin/cleanup_old_miscdumps.sh --miscdumpsdir ${miscdumpsdir} --configfile /etc/dumps/confs/cleanup_misc.conf"
        user        => root,
        minute      => '15',
        hour        => '7',
        require     => File['/usr/local/bin/cleanup_old_miscdumps.sh'],
    }
}
