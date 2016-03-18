# a mediawiki maintenance cron job to refresh link
define mediawiki::maintenance::refreshlinks::cronjob( $ensure =  $::mediawiki::maintenance::refreshlinks::ensure) {
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
