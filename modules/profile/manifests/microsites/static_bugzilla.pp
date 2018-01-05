# static HTML archive of old Bugzilla tickets
class profile::microsites::static_bugzilla {

    include ::bugzilla_static

    include ::profile::backup::host
    backup::set { 'bugzilla-static' : }
    backup::set { 'bugzilla-backup' : }

    monitoring::service { 'static-bugzilla-http':
        description   => 'Static Bugzilla HTTP',
        check_command => 'check_http_url!static-bugzilla.wikimedia.org!/bug1.html',
    }
}
