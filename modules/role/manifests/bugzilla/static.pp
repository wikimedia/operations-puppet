# manifests/role/bugzilla.pp
# role for a Bugzilla server
class role::bugzilla::static {

    include base::firewall
    system::role { 'role::bugzilla_static': description => 'Static HTML Bugzilla server' }

    ferm::service { 'bugzilla_static_http':
        proto => 'tcp',
        port  => '80',
    }

    include role::backup::host

    backup::set { 'bugzilla-static' : }
    backup::set { 'bugzilla-backup' : }

    include ::bugzilla_static

    monitoring::service { 'static-bugzilla-http':
        description   => 'Static Bugzilla HTTP',
        check_command => 'check_http_url!static-bugzilla.wikimedia.org!/bug1.html',
    }
}

