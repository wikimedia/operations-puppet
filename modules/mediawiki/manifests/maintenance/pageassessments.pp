class mediawiki::maintenance::pageassessments( $ensure = present ) {
	cron { 'pageassessments_cleanup_en':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        minute   => 42,
        hour     => 20,
        monthday => '*',
        command  => '/usr/local/bin/mwscript extensions/PageAssessments/maintenance/purgeUnusedProjects.php --wiki=enwiki > /dev/null',
    }
}

