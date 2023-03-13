# SPDX-License-Identifier: Apache-2.0

# Add a pint Prometheus source to enable runtime checking of alerting
# and recording rules.
define prometheus::pint::source (
    Stdlib::Port $port,
    Wmflib::Ensure $ensure = 'present',
    String $instance = $title,
    String $url_path = $instance,
    Boolean $all_alerts = false,
) {
    include prometheus::pint

    file { "/etc/prometheus/pint.hcl.d/${title}.hcl":
        ensure  => $ensure,
        content => template('prometheus/pint/source.hcl.erb'),
        mode    => '0444',
        notify  => Exec['assemble pint.hcl'],
    }
}
