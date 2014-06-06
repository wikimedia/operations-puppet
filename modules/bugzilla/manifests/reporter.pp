# sets up a user and file for the 'bugzilla_report.php' script
# only parameter: user name that will run this (also used for group)
# requires: passwords::bugzilla for the PHP script to connect to db
class bugzilla::reporter ($bz_report_user = 'reporter') {

    user { 'bzreporter':
        home       => "/home/${bz_report_user}",
        groups     => [ $bz_report_user ],
        managehome => true,
        system     => true,
    }

    require passwords::bugzilla

    file { 'bugzilla_report':
        ensure   => present,
        path     => "/home/${bz_report_user}/bugzilla_report.php",
        owner    => $bz_report_user,
        group    => $bz_report_user,
        mode     => '0550',
        content  => template('bugzilla/scripts/bugzilla_report.php.erb'),
    }

    cron { 'bugzilla_reporter_cron':
        ensure  => 'present',
        command => "php -q /home/reporter/bugzilla_report.php | mail -s \"Bugzilla Weekly Report\" wikitech-l@lists.wikimedia.org > /dev/null",
        user    => reporter,
        hour    => 3,
        minute  => 0,
        weekday => 1, # Monday
    }

}

