# a cronjob for updatequerypages for enwiki
class profile::mediawiki::maintenance::updatequerypages::enwiki::cronjob(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # team label for alerting
    $team_label = 'mediawiki-special-pages'

    profile::mediawiki::periodic_job { 'updatequerypages_lonelypages_s1':
        command  => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Lonelypages',
        interval => '*-15 01:00',
    }

    profile::mediawiki::periodic_job { 'updatequerypages_mostcategories_s1':
        command                 => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostcategories',
        interval                => '*-16 01:00',
        cron_schedule           => '0 1 16 * *',
        team                    => $team_label,
        script_label            => 'UpdateSpecialPages.php-Mostcategories',
        description             => 'Update special pages on s1: Most categories',
        kubernetes              => true,
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 5097600, # 2 months
    }

    profile::mediawiki::periodic_job { 'updatequerypages_mostlinkedtemplates_s1':
        command                 => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostlinkedtemplates',
        interval                => '*-18 01:00',
        cron_schedule           => '0 1 18 * *',
        team                    => $team_label,
        script_label            => 'UpdateSpecialPages.php-Mostlinkedtemplates',
        description             => 'Update special pages on s1: Most linked templates',
        kubernetes              => true,
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 5097600, # 2 months
    }

    profile::mediawiki::periodic_job { 'updatequerypages_uncategorizedcategories_s1':
        command                 => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Uncategorizedcategories',
        interval                => '*-19 01:00',
        cron_schedule           => '0 1 19 * *',
        team                    => $team_label,
        script_label            => 'UpdateSpecialPages.php-Uncategorizedcategories_s1',
        description             => 'Update special pages on s1: Uncategorised categories',
        kubernetes              => true,
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 5097600, # 2 months
    }

    profile::mediawiki::periodic_job { 'updatequerypages_wantedtemplates_s1':
        command                 => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Wantedtemplates',
        interval                => '*-20 01:00',
        cron_schedule           => '0 1 20 * *',
        team                    => $team_label,
        script_label            => 'UpdateSpecialPages.php-Wantedtemplates_s1',
        description             => 'Update special pages on s1: Wanted templates',
        kubernetes              => true,
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 5097600, # 2 months
    }
}
