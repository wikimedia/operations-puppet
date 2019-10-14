# Include this to add cron jobs calling updateSpecialPages.php on all clusters.
class mediawiki::maintenance::updatequerypages( $ensure = present ) {

    file { '/var/log/mediawiki/updateSpecialPages':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => 'mwdeploy',
        mode   => '0664',
    }

    Cron {
            ensure => $ensure,
            user   => $::mediawiki::users::web,
            hour   => 1,
            minute => 0,
            month  => absent,
    }

    # add cron jobs - usage: <cluster>@<day of month> (monthday currently unused, only sets cronjob name)
    # Wikidata has its mostlinked job disabled: T234948
    mediawiki::maintenance::updatequerypages::ancientpages { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18', 'wikitech@19']: }
    mediawiki::maintenance::updatequerypages::fewestrevisions { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18', 'wikitech@19']: }
    mediawiki::maintenance::updatequerypages::wantedpages { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18', 'wikitech@19']: }
    mediawiki::maintenance::updatequerypages::mostrevisions { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18', 'wikitech@19']: }
    mediawiki::maintenance::updatequerypages::mostlinked { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 'wikitech@19']: }
    mediawiki::maintenance::updatequerypages::deadendpages { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18', 'wikitech@19']: }

    mediawiki::maintenance::updatequerypages::enwiki::cronjob { ['updatequerypages-enwiki-only']: }
}
