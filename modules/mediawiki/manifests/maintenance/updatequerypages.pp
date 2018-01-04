# Include this to add cron jobs calling updateSpecialPages.php on all clusters.
class mediawiki::maintenance::updatequerypages( $ensure = present ) {

    file { '/var/log/mediawiki/updateSpecialPages':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => 'mwdeploy',
        mode   => '0664',
    }

    # add cron jobs - usage: <cluster>@<day of month> (monthday currently unused, only sets cronjob name)
    mediawiki::maintenance::updatequerypages::cronjob { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 's8@18', 'silver@19']: }
    mediawiki::maintenance::updatequerypages::enwiki::cronjob { ['updatequerypages-enwiki-only']: }
}
