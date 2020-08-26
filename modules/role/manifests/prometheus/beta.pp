# == Class: role::prometheus::beta
#
# This class provides a Prometheus server used to monitor Beta
# (deployment-prep) labs project.
#
# filtertags: labs-project-deployment-prep

class role::prometheus::beta {
    system::role { 'prometheus':
        description => 'Prometheus server (beta / deployment-prep)',
    }

    class { '::httpd':
        modules => ['proxy', 'proxy_http'],
    }

    include ::profile::prometheus::beta
}
