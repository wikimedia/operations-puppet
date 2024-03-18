# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::bastion::toolforge_cli (
  Stdlib::Fqdn $web_domain = lookup('profile::toolforge::web_domain', {default_value => 'toolforge.org'}),
) {
  package { [
    'toolforge-cli',
    'toolforge-builds-cli',
    'toolforge-envvars-cli',
    'toolforge-jobs-framework-cli',
    'toolforge-webservice',
  ]:
    ensure => installed,
  }

  $harbor_domain = "${::wmcs_project}-harbor.wmcloud.org"
  $cli_config = {
    'api_gateway'   => {
      'url' => "https://api.svc.${::wmcs_project}.eqiad1.wikimedia.cloud:30003",
    },
    'build' => {
      'dest_repository' => $harbor_domain,
      'builder_image'   => "${harbor_domain}/toolforge/heroku-builder-classic:22",
      'builds_endpoint' => '/builds/v1',
    },
  }

  file { '/etc/toolforge':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
  }

  # toolforge cli configuration file (toolforge-weld >=1.1.0)
  file { '/etc/toolforge/common.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => $cli_config.to_yaml,
  }

  # TODO: this should use weld config loading or be removed entirely by T348755
  file { '/etc/toolforge/webservice.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => {
      'public_domain'           => $web_domain,
      'buildservice_repository' => $harbor_domain,
    }.to_yaml,
  }

  # old configuration files no longer used
  file { [
    '/etc/toolforge-cli.yaml',
    '/etc/toolforge-jobs-framework-cli.cfg',
  ]:
    ensure => absent,
  }
}
