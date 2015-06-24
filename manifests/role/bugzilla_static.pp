# manifests/role/bugzilla.pp
# role for a Bugzilla server
class role::bugzilla_static {

    system::role { 'role::bugzilla_static': description => 'Static HTML Bugzilla server' }

    ferm::service { 'bugzilla_static_http':
        proto => 'tcp',
        port  => '80',
    }

    include ::bugzilla_static
}

