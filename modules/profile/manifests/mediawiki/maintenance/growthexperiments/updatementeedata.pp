# update data for the mentor dashboard (T285811)
define profile::mediawiki::maintenance::growthexperiments::updatementeedata() {
    # name is the DB cluster
    profile::mediawiki::periodic_job { "growthexperiments-updateMenteeData-${name}":
        command  => "/usr/local/bin/foreachwikiindblist 'growthexperiments & ${name}' extensions/GrowthExperiments/maintenance/updateMenteeData.php --statsd",
        interval => '*-*-* 04:15:00',
    }
}
