class role::snapshot::monitor {
    include role::snapshot::common

    if hiera('snapshot::dumps::monitor', false) {
        # monitor job
        include ::snapshot::dumps::monitor

        system::role { 'role::snapshot::dumps::monitor':
            description => 'monitor of XML dumps',
        }
    }
}
