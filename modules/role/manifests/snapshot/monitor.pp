class role::snapshot::monitor {
    include role::snapshot::common

    if hiera('snapshot::dumps::monitor', false) {
        # monitor job
        include ::snapshot::dumps::monitor

        system::role { 'snapshot::monitor':
            description => 'monitor of XML dumps',
        }
    }
}
