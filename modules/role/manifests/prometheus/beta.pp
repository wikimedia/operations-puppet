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
        # rewrite needed in ::prometheus::web to redirect homepage
        modules => ['proxy', 'proxy_http', 'rewrite'],
    }

    include ::profile::prometheus::beta
}
