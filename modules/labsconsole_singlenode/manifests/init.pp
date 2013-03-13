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
    require       => File[$config_path],
    install_path  => $install_path,
    apache_site_content => 'labsconsole_singlenode/labsconsole.wmflabs.org.erb',
  }

  apache_module { 'ssl':
    name => 'ssl',
  }

  file { "${install_path}/skins/common/images/test-labs-logo.png":
    ensure => present,
    source => 'puppet:///modules/labsconsole_singlenode/test-labs-logo.png',
  }

  mediawiki_singlenode::mw-extension { [ 'Echo', 'CentralAuth', 'Collection', 'DynamicSidebar',
          'LdapAuthentication', 'OATHAuth', 'OpenStackManager',
          'SemanticForms', 'SemanticMediaWiki', 'SemanticResultFormats',
          'Validator', 'WikiEditor', 'CodeEditor', 'Scribunto',
          'Renameuser', 'SyntaxHighlight_GeSHi',
          'Cite', 'Vector', 'Gadgets', 'CategoryTree', 'ParserFunctions',
          'TitleBlacklist', 'DataValues']:
    ensure       => present,
    install_path => '/srv/org/wikimedia/controller/wikis/w';
  }

  exec { 'setup-swm':
    require => Mediawiki_singlenode::Mw-extension['SemanticMediaWiki'],
    command => "/usr/bin/php ${install_path}/extensions/SemanticMediaWiki/maintenance/SMW_setup.php"
  }

    $host_address = $::labs_mediawiki_hostname
    $ldap_user_pass = $passwords::openstack::nova::nova_ldap_user_pass
    $proxyagent_pass = $passwords::openstack::nova::nova_ldap_proxyagent_pass

  file {
    "${config_path}/Settings.php":
      ensure  => present,
      content => template('labsconsole_singlenode/Settings.php.erb'),
      require => file[$config_path];
    "${config_path}/Local.php":
      ensure  => present,
      content => template('labsconsole_singlenode/Local.php.erb'),
      require => file[$config_path];
    "${config_path}/Debug.php":
      ensure  => present,
      content => template('labsconsole_singlenode/Debug.php.erb'),
      require => file['/srv/org/wikimedia/controller/wikis/config'];
    "${config_path}/Private.php":
      ensure  => present,
      content => template('labsconsole_singlenode/Private.php.erb'),
      require => file[$config_path];
    "${install_path}/labsconsole-initial-pages.xml":
      ensure  => present,
      require => Git::Clone['mediawiki'],
      source  => 'puppet:///modules/labsconsole_singlenode/labsconsole-initial-pages.xml';
  }

  exec { 'import_labsconsole_initial_pages':
    require   => File["${install_path}/labsconsole-initial-pages.xml"],
    cwd       => $install_path,
    command   => '/usr/bin/php maintenance/importDump.php labsconsole-initial-pages.xml',
    logoutput => 'on_failure',
    notify    => service['memcached'];
  }

  include role::ldap::server::labs, role::nova::compute, role::nova::controller
}
