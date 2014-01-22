# sets up a user and file for the 'bugzilla_report.php' script
# only parameter: user name that will run this (also used for group)
# requires: passwords::bugzilla for the PHP script to connect to db
class bugzilla::reporter ($bz_report_user = 'reporter') {

    generic::systemuser { 'bzreporter':
        name   => $bz_report_user,
        home   => "/home/${bz_report_user}",
        groups => [ $bz_report_user ]
    }

    require passwords::bugzilla

    file { 'bugzilla_report':
        ensure  => present,
        path    => "/home/${bz_report_user}/bugzilla_report.php",
        owner   => $bz_report_user,
        group   => $bz_report_user,
        mode    => '0550',
        source  => 'puppet:///bugzilla/bugzilla_report.php',
    }

}

