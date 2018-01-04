# Include this to add cron jobs calling refreshLinks.php on all clusters. (T80599)
class mediawiki::maintenance::refreshlinks( $ensure = present ) {

    require ::mediawiki

    file { [ '/var/log/mediawiki/refreshLinks' ]:
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => 'mwdeploy',
        mode   => '0664',
    }

    # add cron jobs - usage: <cluster>@<day of month> (these are just needed monthly)
    mediawiki::maintenance::refreshlinks::cronjob { ['s1@1', 's2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7', 's8@8', 'silver@9']: }
}
