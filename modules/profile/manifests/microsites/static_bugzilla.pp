# static HTML archive of old Bugzilla tickets
class profile::microsites::static_bugzilla {

    class {'::httpd':
        modules => ['headers', 'rewrite'],
    }

    include ::bugzilla_static

    ferm::service { 'bugzilla_static_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

    include ::profile::backup::host
    backup::set { 'bugzilla-static' : }
    backup::set { 'bugzilla-backup' : }

    monitoring::service { 'static-bugzilla-http':
        description   => 'Static Bugzilla HTTP',
        check_command => 'check_http_url!static-bugzilla.wikimedia.org!/bug1.html',
    }
}
