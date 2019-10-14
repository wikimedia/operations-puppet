define mediawiki::maintenance::updatequerypages::ancientpages() {
    $db_cluster = regsubst($name, '@.*', '\1')
    cron { "cron-updatequerypages-ancientpages-${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Ancientpages > /var/log/mediawiki/updateSpecialPages/${name}-AncientPages.log 2>&1",
        monthday => [8, 22],
    }
}
