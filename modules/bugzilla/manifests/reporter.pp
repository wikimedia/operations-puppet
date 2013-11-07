# setup user and script for bugzilla reporter
# parameters: user name that will run this (also used for group)

class bugzilla::reporter ($bz_report_user = 'reporter') {

    systemuser { 'bzreporter':
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

