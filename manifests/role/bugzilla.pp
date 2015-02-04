# manifests/role/bugzilla.pp
# role for a Bugzilla server
class role::bugzilla {

    system::role { 'role::bugzilla': description => 'Bugzilla server' }

    class { '::bugzilla':
        db_host => 'm1-master.eqiad.wmnet',
        db_name => 'bugzilla',
        db_user => 'bugs',
    }

    ferm::service { 'bugzilla_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'bugzilla_https':
        proto => 'tcp',
        port  => '443',
    }

    include ::bugzilla::static
}

