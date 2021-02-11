# @summary Standalone IDP class for creating an instance in WM cloud
class profile::idp::standalone {
    # Standard stuff
    include profile::standard
    include profile::base::firewall

    # configure database
    include profile::mariadb::packages_wmf
    class {'mariadb::service': }
    class {'mariadb::config':
      basedir => '/usr',
      config  => 'role/mariadb/mysqld_config/misc.my.cnf.erb',
      datadir => '/srv/sqldata',
    }
    # TODO: configure openldap
    #  https://wikitech.wikimedia.org/wiki/Standalone-slapd

    # configure IDP
    include profile::idp
    include profile::java
    # Set up test web application
    class {'httpd': modules => ['proxy_http', 'proxy']}
    include profile::idp::client::httpd
    ferm::service {'http-idp-test-login':
      proto => 'tcp',
      port  => 80,
    }
}
