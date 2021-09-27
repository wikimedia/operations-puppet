class profile::microsites::os_reports {
    $docroot  = '/srv/org/wikimedia/os-reports'
    wmflib::dir::mkdir_p($docroot)

    httpd::site { 'os-reports.wikimedia.org':
        content => template('role/apache/sites/os-reports.wikimedia.org.erb'),
    }
}
