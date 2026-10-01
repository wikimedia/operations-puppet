# SPDX-License-Identifier: Apache-2.0
# @summary Runs Hiddenparma in a container
class profile::wmcs::waf::hiddenparma (
  String[1]        $tag                      = lookup('profile::wmcs::waf::hiddenparma::tag'),
  Stdlib::Fqdn     $domain                   = lookup('profile::wmcs::waf::hiddenparma::domain', {default_value => 'requestctl.wmcloud.org'}),
  Stdlib::Host     $db_host                  = lookup('profile::wmcs::waf::hiddenparma::db_host'),
  String[1]        $db_name                  = lookup('profile::wmcs::waf::hiddenparma::db_name', {default_value => 'hiddenparma'}),
  String[1]        $db_user                  = lookup('profile::wmcs::waf::hiddenparma::db_user', {default_value => 'hiddenparma'}),
  String[1]        $db_pass                  = lookup('profile::wmcs::waf::hiddenparma::db_pass'),
  String[1]        $csrf_shared_secret       = lookup('profile::wmcs::waf::hiddenparma::csrf_shared_secret'),
  String[1]        $api_token_encryption_key = lookup('profile::wmcs::waf::hiddenparma::api_token_encryption_key'),
  String[1]        $session_secret_key       = lookup('profile::wmcs::waf::hiddenparma::session_secret_key'),
  Apereo_cas::Urls $apereo_cas               = lookup('apereo_cas'),
) {
  require profile::docker::engine

  # We allow:
  $authorized_groups = [
    # Members of the 'project-proxy' Cloud VPS project (which hosts the shared proxy service)
    'cn=project-project-proxy,ou=groups,dc=wikimedia,dc=org',
    # Cloud VPS admins
    'cn=project-admin,ou=groups,dc=wikimedia,dc=org',
    # Toolforge admins
    'cn=tools.admin,ou=servicegroups,dc=wikimedia,dc=org',
    # Global roots
    'cn=ops,ou=groups,dc=wikimedia,dc=org',
  ]

  service::docker { 'hiddenparma':
    image_name   => 'repos/sre/hiddenparma',
    version      => $tag,
    port         => 8080,
    host_network => true,
    bind_mounts  => {
      '/etc/conftool'           => '/etc/conftool',
      '/etc/etcd'               => '/etc/etcd',
      '/etc/hiddenparma/etcdrc' => '/home/somebody/.etcdrc',
    },
    environment  => {
      'APP_ENV'                  => 'production',
      # TODO: this should allow multiple groups
      'READ_WRITE_GROUP'         => $authorized_groups[0],
      'AUTHORIZED_GROUPS'        => $authorized_groups.join(':'),
      'CSRF_SHARED_SECRET'       => $csrf_shared_secret,
      'DATACENTERS'              => $::wmcs_deployment,
      'DBSTORE_DSN'              => "mariadb+pymysql://${db_user}:${db_pass}@${db_host}/${db_name}?charset=utf8mb4",
      'WEB_AUTH_BACKEND'         => 'native_cas',
      'API_AUTH_BACKEND'         => 'api_token_from_db',
      'API_TOKEN_ENCRYPTION_KEY' => $api_token_encryption_key,
      'CAS_SERVER_URL'           => $apereo_cas['production']['login_url'],
      'CAS_SERVICE_URL'          => "https://${domain}/cas/callback",
      'CAS_USER_ATTRIBUTE'       => 'username',
      'SESSION_SECRET_KEY'       => $session_secret_key,
    },
  }

  file { '/etc/hiddenparma/etcdrc':
    ensure    => file,
    source    => '/root/.etcdrc',
    # 'somebody' user inside the container that the app runs as
    owner     => '65533',
    group     => '65533',
    mode      => '0440',
    show_diff => false,
    require   => Etcd::Client::Config['/root/.etcdrc'],
    notify    => Service['hiddenparma'],
  }
}
