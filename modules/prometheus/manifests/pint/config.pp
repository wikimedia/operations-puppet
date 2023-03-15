# SPDX-License-Identifier: Apache-2.0

# Add a pint configuration snippet
define prometheus::pint::config (
    Wmflib::Ensure $ensure = 'present',
    Optional[Stdlib::Filesource] $source  = undef,
    Optional[String]             $content = undef,
) {
    include prometheus::pint

    file { "/etc/prometheus/pint.hcl.d/${title}.hcl":
        ensure  => $ensure,
        source  => $source,
        content => $content,
        mode    => '0444',
        notify  => Exec['assemble pint.hcl'],
    }
}
