class mediawiki::maintenance::pageassessments( $ensure = present ) {
    cron { 'pageassessments_cleanup':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        minute   => 42,
        hour     => 20,
        monthday => '*',
        command  => '/usr/local/bin/foreachwiki extensions/PageAssessments/maintenance/purgeUnusedProjects.php > /dev/null',
    }
}

