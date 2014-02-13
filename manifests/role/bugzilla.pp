# manifests/role/bugzilla.pp

class role::bugzilla {

    system::role { 'role::bugzilla': description => '(new/upcoming) Bugzilla server' }

    class { '::bugzilla':
        db_host => 'db1001.eqiad.wmnet',
        db_name => 'bugzilla',
        db_user => 'bugs',
    }

}

