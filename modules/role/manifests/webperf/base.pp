# == Class: role::webperf::base
#
# This role provisions a set of front-end monitoring tools that feed
# into StatsD.
#
class role::webperf::base {

    include ::standard
    include ::profile::base::firewall

    include ::profile::webperf::base
}
