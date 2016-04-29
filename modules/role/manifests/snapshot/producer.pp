class role::snapshot::producer {
    include role::snapshot::common

    include ::snapshot
    include ::snapshot::dumps

    system::role { 'role::snapshot::producer':
        description => 'producer of XML dumps',
    }
}

