class mediawiki::maintenance::echo_mail_batch( $ensure = present ) {
    cron { 'echo_mail_batch':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/echo.dblist extensions/Echo/maintenance/processEchoEmailBatch.php > /dev/null 2>&1',
        user    => $::mediawiki::users::web,
        minute  => 0,
        hour    => 0,
    }
}

