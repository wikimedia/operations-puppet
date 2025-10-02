# SPDX-License-Identifier: Apache-2.0
# @summary Configures a HAProxy resolvers snippet with the system DNS
#  resolver addressese
class profile::haproxy::resolver () {
  haproxy::site { 'resolver':
    content => template('profile/haproxy/resolver/haproxy.conf.erb'),
  }
}
