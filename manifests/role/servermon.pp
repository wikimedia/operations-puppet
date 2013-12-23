#

class role::servermon {
    class { '::servermon':
        ensure    => 'present',
        directory => '/srv/deployment/servermon/servermon',
    }

    deployment::target {'servermon': }
}
