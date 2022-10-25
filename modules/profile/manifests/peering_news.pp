# SPDX-License-Identifier: Apache-2.0
# == Class: peering_news
#
# == Parameters
#
# [*proxy*]
#   Proxy to reach the Internet. In URL format.
#
# [*emailto*]
#   Peering News emails recipient.
#
# [*config*]
#   Path to API-KEY.
#
class profile::peering_news(
  Stdlib::Email              $emailto = lookup('profile::peering_news::emailto'),
  Optional[Stdlib::HTTPUrl]  $proxy   = lookup('http_proxy'),
  Optional[Stdlib::Unixpath] $config  = lookup('profile::peering_news::config'),
) {
    class { 'peering_news':
        proxy   => $proxy,
        emailto => $emailto,
        config  => $config
    }
}
