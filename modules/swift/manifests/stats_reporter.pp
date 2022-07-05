# SPDX-License-Identifier: Apache-2.0
class swift::stats_reporter (
    Wmflib::Ensure       $ensure,
    String               $swift_cluster,
    Hash[String, Hash]   $accounts,
    Hash[String, String] $credentials,
){

    class { 'swift::stats::dispersion':
        ensure        => $ensure,
        swift_cluster => $swift_cluster,
        statsd_host   => 'localhost',
        statsd_port   => '9125',
    }

    class { 'swift::stats::accounts':
        ensure        => $ensure,
        swift_cluster => $swift_cluster,
        accounts      => $accounts,
        credentials   => $credentials,
        statsd_host   => 'localhost',
        statsd_port   => '9125',
    }
}
