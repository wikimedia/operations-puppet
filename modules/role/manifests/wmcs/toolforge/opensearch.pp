# SPDX-License-Identifier: Apache-2.0
class role::wmcs::toolforge::opensearch {
  include profile::firewall
  include profile::toolforge::base

  include profile::opensearch::server
}
