class profile::toolforge::services::aptly(
) {
    aptly::repo { 'bookworm-tools':
        publish => true,
    }
    aptly::repo { 'bullseye-tools':
        publish      => true,
    }
    aptly::repo { 'buster-tools':
        publish      => true,
    }

    # its interesting to serve some packages to toolsbeta for testing purposes
    aptly::repo { 'bookworm-toolsbeta':
        publish => true,
    }
    aptly::repo { 'bullseye-toolsbeta':
        publish      => true,
    }
    aptly::repo { 'buster-toolsbeta':
        publish      => true,
    }
}
