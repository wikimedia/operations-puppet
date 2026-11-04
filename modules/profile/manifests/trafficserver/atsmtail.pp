# SPDX-License-Identifier: Apache-2.0
# == Define: profile::trafficserver::atsmtail
#
# Mtail service setup for Trafficserver.
#
define profile::trafficserver::atsmtail(
    String                 $atsmtail_log_basename,
    String                 $atsmtail_unit_suffix,
    Stdlib::Absolutepath   $atsmtail_progs,
    Stdlib::Port::User     $atsmtail_port,
    Systemd::Service::Name $wanted_by,
    String                 $mtail_args = '',
) {
    systemd::service { "atsmtail@${atsmtail_unit_suffix}":
        ensure  => present,
        restart => true,
        content => systemd_template('atsmtail@'),
    }
}
