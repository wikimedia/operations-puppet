# SPDX-License-Identifier: Apache-2.0
class profile::opentelemetry::collector(
    Optional[Stdlib::Host] $otel_gateway_fqdn      = lookup('profile::opentelemetry::otel_gateway_fqdn', {'default_value' => undef}),
    Optional[Stdlib::Port] $otel_gateway_otlp_port = lookup('profile::opentelemetry::otel_gateway_otlp_port', {'default_value' => 30443}),
)
{
    class { 'opentelemetry::collector':
        ensure                 => present,
        otel_gateway_fqdn      => $otel_gateway_fqdn,
        otel_gateway_otlp_port => $otel_gateway_otlp_port,
    }
}
