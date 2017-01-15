# Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)
class mediawiki::maintenance::refreshlinks( $ensure = present ) {

    require ::mediawiki

    file { [ '/var/log/mediawiki/refreshLinks' ]:
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => 'mwdeploy',
        mode   => '0664',
    }

    # add cron jobs - usage: <cluster>@<day of month> (these are just needed monthly)
    cronjob { ['s1@1', 's2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7', 'silver@8']: }
}
