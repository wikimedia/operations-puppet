# SPDX-License-Identifier: Apache-2.0
class profile::swift::swiftrepl(
    $ensure = lookup('profile::swift::swiftrepl::ensure', { 'default_value' => 'present' }),
){

    $source_site = $::site

    case $source_site {
        'eqiad': {
            $destination_site = 'codfw'
        }
        'codfw': {
            $destination_site = 'eqiad'
        }
        default: { fail("Unsupported source site ${::site}") }
    }

    class { '::swift::swiftrepl':
        ensure           => $ensure,
        destination_site => $destination_site,
        source_site      => $source_site,
    }
}
