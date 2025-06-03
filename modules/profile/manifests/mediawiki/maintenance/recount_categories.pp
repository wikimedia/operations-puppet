class profile::mediawiki::maintenance::recount_categories(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team_name = 'mediawiki-categories'

    profile::mediawiki::periodic_job { 'recount_categories':
        command                   => '/usr/local/bin/foreachwiki recountCategories.php --mode all',
        interval                  => '*-*-01 04:00',
        cron_schedule             => '0 4 1 * *',
        kubernetes                => true,
        team                      => $team_name,
        script_label              => 'recountCategories.php',
        description               => 'Recount category membership counts in the category once a month',
        helmfile_defaults_dir     => $helmfile_defaults_dir,
        ttlsecondsafterfinished   => 5097600, # 2 months
        foreachwiki_ignore_errors => true,
    }
}
