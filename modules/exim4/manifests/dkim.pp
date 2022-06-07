# SPDX-License-Identifier: Apache-2.0
# == Define: exim4::dkim
#
# This definition installs a DKIM key under the exim4 DKIM directory hierarchy
#
# == Parameters
#
# [*domain*]
#   The DKIM key domain. Required.
#
# [*Selector*]
#   The DKIM key selector. Required.
#
# [*source*]
#    Source of the file. Either source or content is required
#
# [*content*]
#    Content of the file. Either source or content is required

define exim4::dkim(
  $domain,
  $selector,
  $source=undef,
  $content=undef,
) {
    if $source != undef and $content != undef {
        fail('Both source and content attribute have been defined')
    }

    $keyfile = "/etc/exim4/dkim/${domain}-${selector}.key"

    file { $keyfile:
        ensure    => present,
        owner     => 'root',
        group     => 'Debian-exim',
        mode      => '0440',
        require   => File['/etc/exim4/dkim'],
        notify    => Service['exim4'],
        show_diff => false,
    }

    if $source != undef {
        File[$keyfile] {
            source => $source,
        }
    } elsif $content != undef {
        File[$keyfile] {
            content => $content,
        }
    } else {
        fail('Either source or content attribute needs to be given')
    }
}
