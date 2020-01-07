# This profile installs docker-report, and runs the report with the required frequency.
class profile::docker::reporter(
    String $proxy = lookup('http_proxy')
) {
    package { 'python3-docker-report':
        ensure => present,
    }

    # Report on base images and production-images
    profile::docker::reporter::report { 'base':
        frequency => 'daily',
        proxy     => $proxy,
    }

    # Report on releng images
    profile::docker::reporter::report { 'releng':
        frequency => 'weekly',
        proxy     => $proxy,
    }

    # Report on images used in production on k8s
    profile::docker::reporter::report { 'k8s':
        frequency => 'weekly',
        proxy     => $proxy,
    }
}
