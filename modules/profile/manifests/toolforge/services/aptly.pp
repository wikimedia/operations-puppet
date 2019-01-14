class profile::toolforge::services::aptly(
) {
    aptly::repo { 'stretch-tools':
        publish      => true,
    }
    aptly::repo { 'jessie-tools':
        publish      => true,
    }
}
