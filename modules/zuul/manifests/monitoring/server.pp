# == Class zuul::monitoring::server
#
# Prometheus based monitoring for the Zuul gearman server
#
# Monitor zuul's gearman server. We don't need to monitor the service
# itself as that's covered by our global SystemdUnitFailed alerts.
#
# == Parameters
#
# [*ensure*]
#
class zuul::monitoring::server (
    Wmflib::Ensure $ensure = present,
) {

    # only probe the active master host, the zuul service is stopped on the
    # warm standby server
    if $ensure == 'present' {
        prometheus::blackbox::check::tcp { 'zuul-gearman':
            team          => 'collaboration-services-releng',
            severity      => 'critical',
            port          => 4730,
            timeout       => '2s',
            # python-gear listens on IPv4 only
            ip_families   => ['ip4'],
            probe_runbook => 'https://www.mediawiki.org/wiki/Continuous_integration/Zuul',
        }
    }

    # Installs a particular mtail program into /etc/mtail/
    mtail::program { 'zuul_error_log':
      source => 'puppet:///modules/mtail/programs/zuul_error_log.mtail',
    }
}
