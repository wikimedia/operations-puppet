# = Class: role::discovery::bayes
#
# This class sets up R and Python packages for Bayesian inference.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this role to instances running on
# Debian (Jessie or newer).
#
# filtertags: labs-project-discovery-stats
class role::product_analytics::bayes {
    # include ::profile::standard
    # include ::profile::base::firewall
    include ::profile::product_analytics::probabilistic_programming

    system::role { 'role::product_analytics::bayes':
        ensure      => 'present',
        description => 'VM configured for Bayesian inference',
    }

}
