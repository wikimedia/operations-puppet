# manifests/role/bugzilla.pp
# role for a Bugzilla server
class role::bugzilla_static {

    system::role { 'role::bugzilla_static': description => 'Static HTML Bugzilla server' }

    ferm::service { 'bugzilla_static_http':
        proto => 'tcp',
        port  => '80',
    }

    backup::set { 'bugzilla-static' : }
    backup::set { 'bugzilla-backup' : }

    include ::bugzilla_static
}

