# = Class: role::product_analytics::allstar_cruncher
#
# This class sets up R and Python packages for number crunching, statistical
# computing, forecasting, Bayesian inference, and machine learning (including
# deep neural networks). Once it's up and running: get your game on, go play.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this profile (and any profiles or
# roles that include it) to instances running on Debian (Stretch or newer).
#
# filtertags: labs-project-discovery-stats
class role::product_analytics::allstar_cruncher {
    # include ::profile::standard
    # include ::profile::base::firewall
    include ::profile::product_analytics::forecasting
    # ^ includes ::profile::product_analytics::probabilistic_programming
    include ::profile::product_analytics::machine_learning
    include ::profile::product_analytics::deep_learning

    system::role { 'role::product_analytics::allstar_cruncher':
        ensure      => 'present',
        description => 'VM configured for multi-purpose statistical computing',
    }

}
