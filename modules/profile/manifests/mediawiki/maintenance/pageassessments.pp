class profile::mediawiki::maintenance::pageassessments(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    profile::mediawiki::periodic_job { 'pageassessments_cleanup':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/pageassessments.dblist extensions/PageAssessments/maintenance/purgeUnusedProjects.php',
        interval => '20:42',
    }
}

