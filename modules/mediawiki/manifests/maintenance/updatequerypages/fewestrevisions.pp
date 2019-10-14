define mediawiki::maintenance::updatequerypages::fewestrevisions() {
    $db_cluster = regsubst($name, '@.*', '\1')
    cron { "cron-updatequerypages-fewestrevisions-${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Fewestrevisions > /var/log/mediawiki/updateSpecialPages/${name}-FewestRevisions.log 2>&1",
        monthday => [13, 27],
    }
}
