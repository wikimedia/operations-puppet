class mediawiki::maintenance::tor_exit_node( $ensure = present, $wiki = 'aawiki' ) {
    cron { 'tor_exit_node_update':
        ensure  => $ensure,
        command => "PHP=php7.2 /usr/local/bin/mwscript extensions/TorBlock/maintenance/loadExitNodes.php --wiki=${wiki} --force > /dev/null",
        user    => $::mediawiki::users::web,
        minute  => '*/20',
    }
}

