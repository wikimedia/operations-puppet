# SPDX-License-Identifier: Apache-2.0
# Provisions a plugin repository for OpenSearch project related plugins
class profile::opensearch::plugin_repo {
    file { '/srv/opensearch':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755'
    }
}
