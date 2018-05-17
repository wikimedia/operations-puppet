# == Class: role::webperf::profiling_tools
#
# This role provisions a set of profiling tools for
# the performance team. (T194390)
#
class role::webperf::profiling_tools {

    interface::add_ip6_mapped { 'main': } # lint:ignore:wmf_styleguide

    include ::standard
    include ::profile::base::firewall

    # include ::profile::webperf::xhprof
    # include ::profile::webperf::xhgui
    # include ::profile::webperf::...?

    ferm::service { 'webperf-profiling-tools-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$INTERNAL',
    }

    # TODO: move to individual profile?
    ferm::service { 'webperf-profiling-tools-27017':
        proto  => 'tcp',
        port   => '27017',
        srange => '$INTERNAL',
    }

}
