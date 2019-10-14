define mediawiki::maintenance::updatequerypages::mostlinked() {
    $db_cluster = regsubst($name, '@.*', '\1')
    cron { "cron-updatequerypages-mostlinked-${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Mostlinked > /var/log/mediawiki/updateSpecialPages/${name}-MostLinked.log 2>&1",
        monthday => [10, 24],
    }
}
