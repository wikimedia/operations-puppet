class profile::microsites::os_reports (
    Stdlib::Host $os_reports_host = lookup('profile::sre::os_reports::host'),
) {
    $docroot  = '/srv/org/wikimedia/os-reports'
    wmflib::dir::mkdir_p($docroot)

    httpd::site { 'os-reports.wikimedia.org':
        content => template('role/apache/sites/os-reports.wikimedia.org.erb'),
    }

    ensure_packages('rsync')

    systemd::timer::job { 'sync_os_reports':
        ensure          => present,
        description     => 'Sync OS migration reports/overview',
        user            => 'root',
        logging_enabled => false,
        send_mail       => false,
        command         => "/usr/bin/rsync -tr rsync://${os_reports_host}/osreports/ ${docroot}",
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-* 03:00:00'},
    }
}
