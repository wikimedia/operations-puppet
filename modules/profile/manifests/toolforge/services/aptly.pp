class profile::toolforge::services::aptly(
) {
    aptly::repo { 'buster-tools':
        publish      => true,
    }
    aptly::repo { 'stretch-tools':
        publish      => true,
    }

    # its interesting to serve some packages to toolsbeta for testing purposes
    aptly::repo { 'stretch-toolsbeta':
        publish      => true,
    }
    aptly::repo { 'buster-toolsbeta':
        publish      => true,
    }
}
