class mediawiki::maintenance::initsitestats( $ensure = present ) {
    cron { 'initsitestats':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        minute   => 39,
        hour     => 05,
        monthday => '1,15',
        command  => '/usr/local/bin/foreachwiki initSiteStats.php --update > /dev/null',
    }
}
