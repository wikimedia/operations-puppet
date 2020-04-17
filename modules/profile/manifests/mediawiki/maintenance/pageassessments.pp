class profile::mediawiki::maintenance::pageassessments {
    profile::mediawiki::periodic_job { 'pageassessments_cleanup':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/pageassessments.dblist extensions/PageAssessments/maintenance/purgeUnusedProjects.php',
        interval => '20:42',
    }
}

