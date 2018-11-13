class profile::toolforge::services::aptly() {
    # generic aptly server role
    include profile::aptly::server

    # while working with the dual grid in tools/toolsbeta
    aptly::repo { 'stretch-toolsbeta':
        publish      => true,
    }
}
