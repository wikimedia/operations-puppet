class profile::toolforge::services::aptly(
) {
    aptly::repo { 'bullseye-tools':
        publish      => true,
    }
    aptly::repo { 'buster-tools':
        publish      => true,
    }

    # its interesting to serve some packages to toolsbeta for testing purposes
    aptly::repo { 'bullseye-toolsbeta':
        publish      => true,
    }
    aptly::repo { 'buster-toolsbeta':
        publish      => true,
    }
}
