# static HTML archive of old Bugzilla tickets
class profile::microsites::static_bugzilla {

    system::role { 'role::bugzilla_static': description => 'Static HTML Bugzilla server' }

    include ::bugzilla_static

    # Firewalling
    include ::base::firewall
    ferm::service { 'bugzilla_static_http':
        proto => 'tcp',
        port  => '80',
    }

    # Backups
    include ::role::backup::host

    backup::set { 'bugzilla-static' : }
    backup::set { 'bugzilla-backup' : }

    # Monitoring
    monitoring::service { 'static-bugzilla-http':
        description   => 'Static Bugzilla HTTP',
        check_command => 'check_http_url!static-bugzilla.wikimedia.org!/bug1.html',
    }

}
