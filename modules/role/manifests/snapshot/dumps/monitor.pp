class role::snapshot::dumps::monitor {
    include role::snapshot::common

    include ::snapshot
    include ::snapshot::dumps::monitor

    system::role { 'role::snapshot::dumps::monitor':
        description => 'monitor of XML dumps',
    }
}

