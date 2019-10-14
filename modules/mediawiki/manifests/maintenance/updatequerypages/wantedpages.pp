define mediawiki::maintenance::updatequerypages::wantedpages() {
    $db_cluster = regsubst($name, '@.*', '\1')
    cron { "cron-updatequerypages-wantedpages-${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Wantedpages > /var/log/mediawiki/updateSpecialPages/${name}-WantedPages.log 2>&1",
        monthday => [12, 26],
    }
}
