# SPDX-License-Identifier: Apache-2.0
# @summary Sets up the OpenTofu environment for managing
#   Cloud VPS infrastructure resources.
class profile::openstack::base::opentofu (
  String[1]        $region            = lookup('profile::openstack::base::region'),
  Stdlib::Fqdn     $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
  String[1]        $admin_username    = lookup('profile::openstack::base::opentofu::admin_username', {default_value => 'tofuadmin'}),
  String[1]        $admin_password    = lookup('profile::openstack::base::opentofu::admin_password'),
  Stdlib::HTTPSUrl $s3_endpoint       = lookup('profile::openstack::base::opentofu::s3_endpoint'),
  String[1]        $s3_access_key     = lookup('profile::openstack::base::opentofu::s3_access_key'),
  String[1]        $s3_secret_key     = lookup('profile::openstack::base::opentofu::s3_secret_key'),
) {
  apt::package_from_component { 'tofu':
    component => 'thirdparty/tofu',
    packages  => ['tofu'],
  }

  $clouds_file = '/root/.config/openstack/clouds.yaml'

  openstack::util::envscript { 'tofu':
    region                 => $region,
    keystone_api_fqdn      => $keystone_api_fqdn,
    keystone_api_port      => 25357,
    keystone_api_interface => 'admin',
    os_user                => $admin_username,
    os_password            => $admin_password,
    os_project             => 'admin',
    os_user_domain_id      => 'default',
    os_project_domain_id   => 'default',
    clouds_files           => [$clouds_file],
    do_script              => false,
  }

  file { '/root/.tofurc':
    ensure => file,
    source => 'puppet:///modules/profile/openstack/base/opentofu/tofurc',
    owner  => 'root',
    group  => 'root',
    mode   => '0550',
  }

  file { '/root/.config/.tofurc':
    ensure => absent,
  }

  file { '/usr/local/bin/tofu':
    ensure => file,
    source => 'puppet:///modules/profile/openstack/base/opentofu/tofu-wrapper.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
  }

  $tofu_env = {
    # s3 related
    'AWS_ENDPOINT_URL_S3'   => $s3_endpoint,
    'AWS_REGION'            => $region,
    'AWS_ACCESS_KEY_ID'     => $s3_access_key,
    'AWS_SECRET_ACCESS_KEY' => $s3_secret_key,
    # openstack related
    'OS_CLOUD'              => 'tofu',
    'OS_REGION_NAME'        => $region,
  }

  $tofu_env_str = $tofu_env.reduce('') |$memo, $value| {
    "${memo}export ${value[0]}=\"${value[1]}\"\n"
  }

  file { '/etc/tofu.env':
    ensure  => file,
    content => $tofu_env_str,
    owner   => 'root',
    group   => 'root',
    mode    => '0550',
  }

  git::clone { 'repos/cloud/cloud-vps/tofu-infra':
    ensure    => 'latest',
    source    => 'gitlab',
    directory => '/srv/tofu-infra',
    owner     => 'root',
    group     => 'root',
    mode      => '0444',
  }
}
