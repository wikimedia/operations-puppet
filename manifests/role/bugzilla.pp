# manifests/role/bugzilla.pp

class role::bugzilla {

    system::role { "role::bugzilla": description => "Bugzilla server" }

    include misc::bugzilla::server,
            misc::bugzilla::crons,
            misc::bugzilla::communitymetrics,
            misc::bugzilla::report,
            misc::bugzilla::auditlog

}
