# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::bastion::toolforge_cli () {
  package { [
    'toolforge-cli',
    'toolforge-builds-cli',
    'toolforge-envvars-cli',
    'toolforge-jobs-framework-cli',
  ]:
    ensure => installed,
  }

  $cli_config = {
    'api_gateway'   => {
      'url' => "https://api.svc.${::wmcs_project}.eqiad1.wikimedia.cloud:30003",
    },
    'build' => {
      'dest_repository' => "${::wmcs_project}-harbor.wmcloud.org",
      'builder_image'   => "${::wmcs_project}-harbor.wmcloud.org/toolforge/heroku-builder-classic:22",
      'builds_endpoint' => '/builds/v1',
    },
  }

  # toolforge cli configuration file (toolforge-weld >=1.1.0)
  file { '/etc/toolforge/common.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => $cli_config.to_yaml,
  }

  # old configuration file, to be removed once every client uses the new path
  file { '/etc/toolforge-cli.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => $cli_config.to_yaml,
  }

  $jobs_cli_config = {
    api_url    => "https://api.svc.${::wmcs_project}.eqiad1.wikimedia.cloud:30003/jobs/api/v1",
    kubeconfig => '~/.kube/config',
  }

  file { '/etc/toolforge-jobs-framework-cli.cfg':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => $jobs_cli_config.to_yaml,
  }
}
