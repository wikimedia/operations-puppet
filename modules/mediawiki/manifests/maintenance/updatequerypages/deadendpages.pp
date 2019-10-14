define mediawiki::maintenance::updatequerypages::deadendpages() {
    $db_cluster = regsubst($name, '@.*', '\1')
    cron { "cron-updatequerypages-deadendpages-${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Deadendpages > /var/log/mediawiki/updateSpecialPages/${name}-DeadendPages.log 2>&1",
        monthday => [9, 23],
    }
}
