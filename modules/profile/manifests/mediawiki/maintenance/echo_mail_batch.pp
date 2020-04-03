class profile::mediawiki::maintenance::echo_mail_batch {
    profile::mediawiki::periodic_job { 'echo_mail_batch':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/echo.dblist extensions/Echo/maintenance/processEchoEmailBatch.php',
        interval => '00:00',
    }
}

