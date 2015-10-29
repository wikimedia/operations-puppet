class mediawiki::maintenance::refreshlinks( $ensure = present ) {

    require mediawiki

    # Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)

    file { [ '/var/log/mediawiki/refreshLinks' ]:
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => 'mwdeploy',
        mode   => '0664',
    }

    define cronjob( $ensure =  $::mediawiki::maintenance::refreshlinks::ensure) {
        $db_cluster = regsubst($name, '@.*', '\1')
        $monthday = regsubst($name, '.*@', '\1')

        cron { "cron-refreshlinks-${name}":
            ensure   => $ensure,
            command  => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${db_cluster}.dblist --dfn-only > /var/log/mediawiki/refreshLinks/${name}.log 2>&1",
            user     => $::mediawiki::users::web,
            hour     => 0,
            minute   => 0,
            monthday => $monthday,
        }
    }

    # add cron jobs - usage: <cluster>@<day of month> (these are just needed monthly)
    cronjob { ['s1@1', 's2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7', 'silver@8']: }
}
