class role::swift::swiftrepl {

    system::role { 'swift::swiftrepl':
        description => 'swift replication',
    }
    include profile::standard
    include profile::swift::swiftrepl
}
