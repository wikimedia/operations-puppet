class role::snapshot::monitor {
    include role::snapshot::common

    if hiera('snapshot::dumps::monitor', false) {
        # mw packages and dependencies, dataset server nfs mount
        include ::snapshot::dumps::packages

        # config, stages files, dblists, html templates
        include ::snapshot::dumps

        # scap3 deployment of dump scripts
        include dataset::user
        include snapshot::deployment

        # monitor job
        include ::snapshot::dumps::monitor

        system::role { 'role::snapshot::dumps::monitor':
            description => 'monitor of XML dumps',
        }
    }
}
