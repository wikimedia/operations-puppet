# Include this to add periodic jobs calling updateSpecialPages.php on all clusters.
class profile::mediawiki::maintenance::updatequerypages {

    # add periodic jobs - usage: <cluster>@<day of month> (monthday currently unused, only sets cronjob name)
    # Wikidata has several jobs disabled: T234948, T239072
    profile::mediawiki::maintenance::updatequerypages::ancientpages { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18', 'wikitech@19']: }
    profile::mediawiki::maintenance::updatequerypages::fewestrevisions { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 'wikitech@19']: }
    profile::mediawiki::maintenance::updatequerypages::wantedpages { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18', 'wikitech@19']: }
    profile::mediawiki::maintenance::updatequerypages::mostrevisions { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 'wikitech@19']: }
    profile::mediawiki::maintenance::updatequerypages::mostlinked { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 'wikitech@19']: }
    profile::mediawiki::maintenance::updatequerypages::deadendpages { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18', 'wikitech@19']: }

    include profile::mediawiki::maintenance::updatequerypages::enwiki::cronjob
}
