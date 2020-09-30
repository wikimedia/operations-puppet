# filtertags: labs-project-deployment-prep
class profile::swift::stats_reporter (
    Wmflib::Ensure         $ensure        = lookup('profile::swift::stats_reporter::ensure'),
    String                 $swift_cluster = lookup('profile::swift::cluster'),
    Hash[String, Hash]     $accounts      = lookup('profile::swift::accounts'),
    Hash[String, String]   $credentials   = lookup('profile::swift::accounts_keys'),
    Optional[Stdlib::Host] $statsd_host   = lookup('profile::swift::stats_reporter::statsd_host'),
    Optional[Stdlib::Port] $statsd_port   = lookup('profile::swift::stats_reporter::statsd_port'),
){

    class { 'swift::stats::dispersion':
        ensure        => $ensure,
        swift_cluster => $swift_cluster,
        statsd_host   => $statsd_host,
        statsd_port   => $statsd_port,
    }

    class { 'swift::stats::accounts':
        ensure        => $ensure,
        swift_cluster => $swift_cluster,
        accounts      => $accounts,
        credentials   => $credentials,
        statsd_host   => $statsd_host,
        statsd_port   => $statsd_port,
    }
}
