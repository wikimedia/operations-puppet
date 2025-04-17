# Include this to add periodic jobs calling updateSpecialPages.php on all clusters.
class profile::mediawiki::maintenance::updatequerypages(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    # add periodic jobs - usage: <cluster>@<day of month> (monthday currently unused, only sets cronjob name)
    # Wikidata has several jobs disabled: T234948, T239072
    profile::mediawiki::maintenance::updatequerypages::ancientpages { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18']: }
    profile::mediawiki::maintenance::updatequerypages::fewestrevisions { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17']: }
    profile::mediawiki::maintenance::updatequerypages::wantedpages { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18']: }
    profile::mediawiki::maintenance::updatequerypages::mostrevisions { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17']: }
    profile::mediawiki::maintenance::updatequerypages::mostlinked { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17']: }

    # Move away from using a defined resource and use sharded_periodic_job
    # The '@<day of month>' hasn't worked in years, but we keep it for now to make the diff easier to read.
    profile::mediawiki::sharded_periodic_job { 'updatequerypages_deadendpages':
        interval => '*-9,23 01:00',
        shards   => ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18'],
        script   => 'updateSpecialPages.php --override --only=Deadendpages',
    }

    profile::mediawiki::maintenance::updatequerypages::uncatpages { ['s4@14']: }


    include profile::mediawiki::maintenance::updatequerypages::enwiki::cronjob
}
