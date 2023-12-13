# SPDX-License-Identifier: Apache-2.0
# == Class: role::logging::opensearch::data::hd
#
class role::logging::opensearch::data::hd {
    system::role { 'logging::opensearch::data::hd':
      description => 'OpenSearch Data Node HD',
    }

    include profile::base::production
    include profile::firewall
}
