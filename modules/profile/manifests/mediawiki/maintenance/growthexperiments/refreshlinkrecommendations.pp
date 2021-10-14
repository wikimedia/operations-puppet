# Ensure that a sufficiently large pool of link recommendations is available.
define profile::mediawiki::maintenance::growthexperiments::refreshlinkrecommendations() {
    # name is the DB section
    profile::mediawiki::periodic_job { "growthexperiments-refreshLinkRecommendations-${name}":
        command  => "/usr/local/bin/foreachwikiindblist 'growthexperiments & ${name}' extensions/GrowthExperiments/maintenance/refreshLinkRecommendations.php --verbose",
        interval => '*-*-* *:27:00',
    }
}
