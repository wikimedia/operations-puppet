# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::gitlab_tokens(
  String[1] $tofu_infra = lookup('profile::wmcs::gitlab_tokens::tofu_infra', {'default_value' => 'secret_to_override'}),
) {
    file { '/etc/cookbook-wmcs-openstack-tofu-gitlab-private-token.txt':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => "${tofu_infra}\n"
    }
}
