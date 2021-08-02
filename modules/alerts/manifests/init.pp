# Provide the ability to deploy Prometheus alerting rules from git repository (typically
# operations/alerts) into a directory for Prometheus to pick up.
#
# The "deployment directory" is used because:
# * Prometheus doesn't support recursive globbing for rule files, thus we have to flatten directory trees.
# * It allows for further sanity checking pre-deployment, other than CI tests in the repo itself.

class alerts {
    group { 'alerts-deploy':
        ensure => present,
        system => true,
    }

    user { 'alerts-deploy':
        gid        => 'alerts-deploy',
        shell      => '/bin/bash',
        system     => true,
        managehome => true,
        home       => '/var/lib/alerts-deploy',
        require    => Group['alerts-deploy'],
    }

    file { '/usr/local/bin/alerts-deploy':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/alerts/deploy.py',
    }
}
