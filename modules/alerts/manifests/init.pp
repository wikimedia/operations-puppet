# SPDX-License-Identifier: Apache-2.0
# Provide the ability to deploy Prometheus alerting rules from git repository (typically
# operations/alerts) into a directory for Prometheus to pick up.
#
# The "deployment directory" is used because:
# * Prometheus doesn't support recursive globbing for rule files, thus we have to flatten directory trees.
# * It allows for further sanity checking pre-deployment, other than CI tests in the repo itself.

# All alerts-deploy invocations are wrapped in systemd one-shot services
# to get logging, error notification, etc out of the box.

# Calling 'systemctl start alerts-deploy.target' will force-run a deploy
# from the existing git repository (i.e. no git pull first)

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

    # The target to be started after puppet has updated git
    systemd::unit { 'alerts-deploy.target':
        content => "[Unit]\nDescription=alerts-deploy\n",
    }
}
