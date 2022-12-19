# @summary grafana with metricsinfra specific configuration
# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::metricsinfra::grafana (
  Stdlib::Host           $mysql_hostname = lookup('profile::wmcs::metricsinfra::grafana::mysql_hostname', {default_value => 'wu5emp5wblz.svc.trove.eqiad1.wikimedia.cloud'}),
  String[1]              $mysql_database = lookup('profile::wmcs::metricsinfra::grafana::mysql_database', {default_value => 'grafana'}),
  String[1]              $mysql_username = lookup('profile::wmcs::metricsinfra::grafana::mysql_username', {default_value => 'grafana'}),
  String[1]              $mysql_password = lookup('profile::wmcs::metricsinfra::grafana::mysql_password'),
  Array[Stdlib::Fqdn, 1] $grafana_hosts  = lookup('profile::wmcs::metricsinfra::grafana_hosts'),
) {
  class { '::httpd':
    modules => ['headers', 'proxy', 'proxy_http', 'rewrite'],
  }

  class { 'profile::grafana':
    enable_cas       => true,
    config           => {
      'auth'           => {
        disable_login_form   => true,
        disable_signout_menu => true,
      },
      'auth.anonymous' => {
        enabled  => true,
        org_name => 'Wikimedia Cloud Services',
      },
      'auth.basic'     => {
        enabled => true,
      },
      'auth.proxy'     => {
        enabled     => true,
        header_name => 'X-CAS-uid',
      },
      'database'       => {
        type     => 'mysql',
        host     => $mysql_hostname,
        name     => $mysql_database,
        user     => $mysql_username,
        password => $mysql_password,
      },
    },
    logo_file_source => 'puppet:///modules/profile/grafana/logo/wmcs-logo.svg',
  }

  class { 'grafana::ldap_sync':
    ensure => ($::facts['fqdn'] == $grafana_hosts[0]).bool2str('present', 'absent'),
  }
}
