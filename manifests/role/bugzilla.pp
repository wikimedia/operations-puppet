# manifests/role/bugzilla.pp

class role::bugzilla::old {

    system::role { 'role::bugzilla::old': description => '(old/current) Bugzilla server' }

    include misc::bugzilla::server,
            misc::bugzilla::crons,
            misc::bugzilla::communitymetrics,
            misc::bugzilla::report,
            misc::bugzilla::auditlog

}

class role::bugzilla {

    system::role { 'role::bugzilla': description => '(new/upcoming) Bugzilla server' }

    class { '::bugzilla':
        db_host => 'db1001.eqiad.wmnet',
        db_name => 'bugzilla',
        db_user => 'bugs',
    }

}

