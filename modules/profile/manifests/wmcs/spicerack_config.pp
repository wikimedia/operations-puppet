# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::spicerack_config(
  String[1] $gitlab_token = lookup('profile::wmcs::spicerack_config::gitlab_token'),
) {
    $config = {
      gitlab_token => $gitlab_token,
    }
    file { '/etc/spicerack/wmcs.yaml':
      ensure  => present,
      owner   => 'root',
      group   => 'ops',
      mode    => '0440',
      content => to_yaml($config),
    }
}
