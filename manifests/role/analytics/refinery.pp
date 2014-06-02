# NOTE:  This file will replace role/analytics/kraken.pp soon.

# == Class role::analytics::refinery
# Includes configuration and resources needed for deploying
# and using the analytics/refinery repository.
#
class role::analytics::refinery {
    # Many Kraken python scripts use docopt for CLI parsing.
    if !defined(Package['python-docopt']) {
        package { 'python-docopt':
            ensure => 'installed',
        }
    }

    # analytics/refinery will deployed to this node.
    deployment::target { 'analytics-refinery': }

    # analytics/refinery repository is deployed via git-deploy at this path.
    # You must deploy this yourself; puppet will not do it for you.
    $path = '/srv/deployment/analytics/refinery'
}
