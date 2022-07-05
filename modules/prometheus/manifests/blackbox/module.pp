# SPDX-License-Identifier: Apache-2.0

# == Define: prometheus::blackbox::module
#
# A thin wrapper around 'file' resource to perform common validation

define prometheus::blackbox::module (
    Wmflib::Ensure    $ensure = 'present',
    Optional[String]  $source = undef,
    Optional[String]  $content = undef,
) {
    file { "/etc/prometheus/blackbox.yml.d/${title}.yml":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        mode    => '0444',
        notify  => Exec['assemble blackbox.yml'],
    }
}
