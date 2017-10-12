# = Class: role::discovery::bayes
#
# This class sets up R and Python packages for Bayesian inference.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this role to instances running on
# Debian (Jessie or newer).
#
# filtertags: labs-project-discovery-stats
class role::discovery::bayes {
    # include ::standard
    # include ::base::firewall
    include ::profile::discovery_computing::bayesian_statistics

    system::role { 'role::discovery::bayes':
        ensure      => 'present',
        description => 'Bayesian inference for Discovery Analysts',
    }

}
