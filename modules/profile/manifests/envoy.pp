# SPDX-License-Identifier: Apache-2.0
# @summary Sets up a basic installation of the envoy proxy. You will need to define listeners and clusters separately
# @param ensure ensurable parameter
# @param cluster the WMF cluster
# @param runtime the runtime.yaml config
#
class profile::envoy(
    Wmflib::Ensure $ensure = lookup('profile::envoy::ensure'),
    String         $cluster = lookup('cluster'),
    Hash           $runtime = lookup('profile::envoy::runtime', {'default_value' => {}}),
) {
    # Envoy supports tcp fast open
    require profile::tcp_fast_open

    # Work around Let's Encrypt / DST Root CA X3 issues for bundled BoringSSL
    # from T292291
    class { 'sslcert::ca_deselect_dstx3': }

    $pkg_name = 'envoyproxy'
    $use_override = true
    $admin_port = 9631
    class { 'envoyproxy':
        ensure          => $ensure,
        admin_port      => $admin_port,
        pkg_name        => $pkg_name,
        use_override    => $use_override,
        service_cluster => $cluster,
        runtime         => $runtime,
    }

    nrpe::monitor_systemd_unit_state{ 'envoyproxy.service':
        ensure      => $ensure,
        description => 'Check that envoy is running',
        retries     => 2,
        notes_url   => 'https://wikitech.wikimedia.org/wiki/Application_servers/Runbook#Envoy',
    }

    # Check the envoy admin interface to find if the runtime variables have been modified.
    # The check runs every 30 minutes, and in case of failure it's re-tested every 5
    # minutes.
    $command = "/usr/lib/nagios/plugins/check_http -H localhost -I 127.0.0.1 -p ${admin_port} -u /runtime  -s '\"entries\": {}'"
    nrpe::monitor_service{ 'envoy_runtime_vars':
        ensure         => absent,
        description    => 'Check no envoy runtime configuration is left persistent',
        nrpe_command   => $command,
        retries        => 2,
        check_interval => 30,
        retry_interval => 5,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Application_servers/Runbook#Envoy',
    }
}
