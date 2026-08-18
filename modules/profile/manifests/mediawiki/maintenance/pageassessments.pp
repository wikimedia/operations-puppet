class profile::mediawiki::maintenance::pageassessments(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'pageassessments_cleanup':
        command               => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/pageassessments.dblist extensions/PageAssessments/maintenance/purgeUnusedProjects.php',
        interval              => '20:42',
        cron_schedule         => '42 20 * * *',
        kubernetes            => true,
        team                  => 'content-platform-team',
        script_label          => 'purgeUnusedProjects.php',
        description           => 'Remove any unused projects from the page_assessments_projects table (dblist: pageassessments)',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}

