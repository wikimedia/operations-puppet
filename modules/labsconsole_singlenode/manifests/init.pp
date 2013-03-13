#  Configure a labsconsole test instance:  Openstack, Mediawiki, Openstackmanager
#
#  Globals you will want to set:
#  $::mariadb = False
#  $::openstack_version = "essex"
#  $::dns_auth_ipaddress = "127.0.0.1"
#  $::dns_auth_soa_name = "wmflabs.org"
#  $::ldap_certificate = "star.wmflabs"
#  $::ldap_first_master = true
#  $::ldap_server_bind_ips = "127.0.0.1 10.4.0.82"

class labsconsole_singlenode {
  include passwords::openstack::nova

  $db_host = $::realm ? {
    'production' => 'virt0.wikimedia.org',
    'labs' => 'localhost',
  }
  $ldap_server_primary = $::realm ? {
    'production' => 'virt0.wikimedia.org',
    'labs' => 'localhost',
  }
  $ldap_server_secondary = $::realm ? {
    'production' => 'virt1000.wikimedia.org',
    'labs' => 'localhost',
  }

  $wiki_name = 'labsconsole-test'
  $db_name =  $wiki_name
  $mysql_pass = $passwords::openstack::nova::controller_mysql_root_pass
  $initial_password = $passwords::ldap::initial_setup::initial_password

  $wikis_path = '/srv/org/wikimedia/controller/wikis'
  $install_path = "${wikis_path}/w"
  $config_path = "${wikis_path}/config"

  file { ['/srv/org', '/srv/org/wikimedia', '/srv/org/wikimedia/controller', $wikis_path, $config_path]:
      ensure => 'directory',
  }

  class { 'mediawiki_singlenode':
    ensure        => present,
    database_name => $db_name,
    wiki_name     => $wiki_name,
    mysql_pass    => $mysql_pass,
    role_requires => [
        "\'${config_path}/Settings.php\'",
        "\'${config_path}/Private.php\'",
        "\'${config_path}/Local.php\'",
        "\'${config_path}/Debug.php\'",
        ],
    require              => File[$config_path],
    install_path         => $install_path,
    apache_site_template => 'labsconsole_singlenode/labsconsole.wmflabs.org.erb',
  }

  package { [ 'php5', 'php5-cli', 'php5-ldap', 'php5-uuid', 'php5-curl', 'php-luasandbox' ]:
    ensure => present;
  }

  apache_module { 'ssl':
    name => 'ssl',
  }

  file { "${install_path}/skins/common/images/test-labs-logo.png":
    ensure => present,
    source => 'puppet:///modules/labsconsole_singlenode/test-labs-logo.png',
    require      => Class['mediawiki_singlenode'],
  }

  mediawiki_singlenode::mw-extension { [ 'Echo', 'CentralAuth', 'Collection', 'DynamicSidebar',
          'LdapAuthentication', 'OATHAuth', 'OpenStackManager',
          'SemanticForms', 'SemanticMediaWiki', 'SemanticResultFormats',
          'Validator', 'WikiEditor', 'CodeEditor', 'Scribunto',
          'Renameuser', 'SyntaxHighlight_GeSHi',
          'Cite', 'Vector', 'Gadgets', 'CategoryTree', 'ParserFunctions',
          'TitleBlacklist', 'DataValues']:
    require      => Git::Clone['mediawiki'],
    ensure       => present,
    install_path => '/srv/org/wikimedia/controller/wikis/w';
  }

  exec {
    'setup-swm':
      require => [ Mediawiki_singlenode::Mw-extension['SemanticMediaWiki'], Exec['mediawiki_setup'] ],
      cwd     => $install_path,
      command => "/usr/bin/php ${install_path}/extensions/SemanticMediaWiki/maintenance/SMW_setup.php",
      unless  => '/usr/bin/php maintenance/eval.php <<<"die(defined(\'SMW_VERSION\')?0:1)"';
    'setup-ldap-auth':
      require => [ Mediawiki_singlenode::Mw-extension['LdapAuthentication'], Class['mediawiki_singlenode'] ],
      cwd     => $install_path,
      command => "/usr/bin/php ${install_path}/maintenance/update.php",
      unless  => "/usr/bin/mysqlshow ${db_name} ldap\_domains"; # FIXME this doesn't work, probably quoting problem
    'seed-ldap':
      subscribe => Exec['start_opendj'],
      refreshonly => true,
      command => "/usr/bin/ldapadd -c -x -D 'cn=Directory Manager' -h localhost -w ${initial_password} -f /etc/ldap/labsconsole-ldap-seed.ldif",
      require => [Package["ldap-utils"], File['/etc/ldap/labsconsole-ldap-seed.ldif']];
    'import_labsconsole_initial_pages':
      require   => [File["${install_path}/labsconsole-initial-pages.xml"],
                    Class['mediawiki_singlenode']],
      cwd       => $install_path,
      command   => '/usr/bin/php maintenance/importDump.php labsconsole-initial-pages.xml',
      logoutput => 'on_failure',
      notify    => service['memcached'];
  }

  $host_address = $::labs_mediawiki_hostname
  $ldap_user_pass = $passwords::openstack::nova::nova_ldap_user_pass
  $proxyagent_pass = $passwords::openstack::nova::nova_ldap_proxyagent_pass

  file {
    "${config_path}/Settings.php":
      ensure  => present,
      content => template('labsconsole_singlenode/Settings.php.erb'),
      before => Exec['import_privacy_policy'],
      require => file[$config_path];
    "${config_path}/Local.php":
      ensure  => present,
      content => template('labsconsole_singlenode/Local.php.erb'),
      before => Exec['import_privacy_policy'],
      require => file[$config_path];
    "${config_path}/Debug.php":
      ensure  => present,
      content => template('labsconsole_singlenode/Debug.php.erb'),
      before => Exec['import_privacy_policy'],
      require => file[$config_path];
    "${config_path}/Private.php":
      ensure  => present,
      content => template('labsconsole_singlenode/Private.php.erb'),
      before => Exec['import_privacy_policy'],
      require => file[$config_path];
    "${install_path}/labsconsole-initial-pages.xml":
      ensure  => present,
      source  => 'puppet:///modules/labsconsole_singlenode/labsconsole-initial-pages.xml',
      require => Class['mediawiki_singlenode'];
    '/etc/ldap/labsconsole-ldap-seed.ldif':
      ensure  => present,
      source  => 'puppet:///modules/labsconsole_singlenode/labsconsole-ldap-seed.ldif',
      require => [Package["ldap-utils"], File["/etc/ldap/global-aci.ldif"]];
  }

  include role::ldap::server::labs, role::nova::compute, role::nova::controller
}
