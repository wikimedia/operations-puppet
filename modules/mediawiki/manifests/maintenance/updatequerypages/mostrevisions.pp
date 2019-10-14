define mediawiki::maintenance::updatequerypages::mostrevisions() {
    $db_cluster = regsubst($name, '@.*', '\1')
    cron { "cron-updatequerypages-mostrevisions-${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Mostrevisions > /var/log/mediawiki/updateSpecialPages/${name}-MostRevisions.log 2>&1",
        monthday => [11, 25],
    }
}
