# Include this to add periodic jobs calling updateSpecialPages.php on all clusters.
class profile::mediawiki::maintenance::updatequerypages(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team = 'mediawiki-special-pages'

    # add periodic jobs - usage: <cluster>@<day of month> (monthday currently unused, only sets cronjob name)
    # Wikidata has several jobs disabled for performance reasons: T234948, T239072
    # Commons has deadendpages disabled by community request: T371662
    profile::mediawiki::sharded_periodic_job { 'updatequerypages_ancientpages':
        interval                => '*-8,22 01:00',
        cron_schedule           => '00 01 8,22 * *',
        shards                  => ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18'],
        script                  => 'updateSpecialPages.php --override --only=Ancientpages',
        kubernetes              => true,
        team                    => $team,
        description             => 'Update ancientpages',
        script_label            => 'updatequerypages-ancientpages',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }
    profile::mediawiki::sharded_periodic_job { 'updatequerypages_fewestrevisions':
        interval                => '*-13,27 01:00',
        cron_schedule           => '00 01 13,27 * *',
        shards                  => ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17'],
        script                  => 'updateSpecialPages.php --override --only=Fewestrevisions',
        kubernetes              => true,
        team                    => $team,
        description             => 'Update fewestrevisions',
        script_label            => 'updatequerypages-fewestrevisions',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }
    profile::mediawiki::sharded_periodic_job { 'updatequerypages_wantedpages':
        interval                => '*-12,26 01:00',
        cron_schedule           => '00 01 12,26 * *',
        shards                  => ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18'],
        script                  => 'updateSpecialPages.php --override --only=Wantedpages',
        kubernetes              => true,
        team                    => $team,
        description             => 'Update wantedpages',
        script_label            => 'updatequerypages-wantedpages',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }
    profile::mediawiki::sharded_periodic_job { 'updatequerypages_mostrevisions':
        interval                => '*-11,25 01:00',
        cron_schedule           => '00 01 11,25 * *',
        shards                  => ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17'],
        script                  => 'updateSpecialPages.php --override --only=Mostrevisions',
        team                    => $team,
        kubernetes              => true,
        description             => 'Update mostrevisions',
        script_label            => 'updatequerypages-mostrevisions',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }
    profile::mediawiki::sharded_periodic_job { 'updatequerypages_mostlinked':
        interval                => '*-10,24 01:00',
        cron_schedule           => '00 01 10,24 * *',
        shards                  => ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17'],
        script                  => 'updateSpecialPages.php --override --only=Mostlinked',
        kubernetes              => true,
        team                    => $team,
        description             => 'Update mostlinked',
        script_label            => 'updatequerypages-mostlinked',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }

    # Move away from using a defined resource and use sharded_periodic_job
    # The '@<day of month>' hasn't worked in years, but we keep it for now to make the diff easier to read.
    profile::mediawiki::sharded_periodic_job { 'updatequerypages_deadendpages':
        interval                => '*-9,23 01:00',
        cron_schedule           => '00 01 9,23 * *',
        shards                  => ['s1@11', 's2@12', 's3@13', 's5@15', 's6@16', 's7@17', 's8@18'],
        script                  => 'updateSpecialPages.php --override --only=Deadendpages',
        team                    => $team,
        kubernetes              => true,
        description             => 'Update deadendpages',
        script_label            => 'updatequerypages-deadendpages',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }

    profile::mediawiki::sharded_periodic_job { 'updatequerypages_uncatpages':
        interval                => '*-14,28 01:00',
        cron_schedule           => '00 01 14,28 * *',
        shards                  => ['s4@14'],
        script                  => 'updateSpecialPages.php --override --only=Uncategorizedpages',
        kubernetes              => true,
        team                    => $team,
        description             => 'Update uncategorizedpages',
        script_label            => 'updatequerypages-uncatpages',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }

    include profile::mediawiki::maintenance::updatequerypages::enwiki::cronjob
}
