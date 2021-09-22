# a mediawiki maintenance periodic job to refresh link
define profile::mediawiki::maintenance::refreshlinks::periodic_job {
    $db_cluster = regsubst($name, '@.*', '\1')
    $monthday = regsubst($name, '.*@', '\1')

    profile::mediawiki::periodic_job { "cron-refreshlinks-${name}":
        command  => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${db_cluster}.dblist --dfn-only",
        interval => "*-${monthday} 00:00",
    }
}
