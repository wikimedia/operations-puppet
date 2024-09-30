# SPDX-License-Identifier: Apache-2.0
# == Class: opentelemetry::collector
#
# Collects and emits opentelemetry data.
#
# Currently installed from the otelcol-contrib distribution .deb available
# at https://github.com/open-telemetry/opentelemetry-collector-releases/releases
#
# === Parameters
#
# [*ensure*]
#   present/absent
# [*otel_gateway_fqdn*]
#   otel gateway's FQDN
#   default: undef
# [*otel_gateway_otlp_port*]
#   otel-gateway's otlp grpc port
#   default: undef
class opentelemetry::collector(
    Wmflib::Ensure $ensure                         = 'absent',
    Optional[Stdlib::Host] $otel_gateway_fqdn      = undef,
    Optional[Stdlib::Port] $otel_gateway_otlp_port = undef,
) {

    $otel_user = 'otelcol-contrib'
    systemd::sysuser { $otel_user:
        ensure      => $ensure,
        description => 'OpenTelemetry Collector user',
    }

    apt::package_from_component { 'opentelemetry':
        component       => 'thirdparty/otelcol-contrib',
        packages        => { 'otelcol-contrib' => $ensure },
        ensure_packages => true,
    }

    apt::package_from_component { 'otel-cli':
        component       => 'thirdparty/otel-cli',
        packages        => { 'otel-cli' => $ensure },
        ensure_packages => true,
    }

    $service_ensure = $ensure ? {
        'present' => 'running',
        default   => 'stopped',
    }

    service { 'otelcol-contrib':
        ensure => $service_ensure,
    }

    file { '/etc/otelcol-contrib/config.yaml':
        ensure  => $ensure,
        content => template('opentelemetry/config.yaml.erb'),
        owner   => $otel_user,
        group   => $otel_user,
        mode    => '0640',
        notify  => Service['otelcol-contrib'],
        require => Package['otelcol-contrib'],
    }
}
