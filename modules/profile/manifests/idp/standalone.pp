# SPDX-License-Identifier: Apache-2.0
# @summary Standalone IDP class for creating an instance in WM cloud
class profile::idp::standalone {
  ensure_packages(['python3-flask'])
  # Standard stuff
  include profile::base::production
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
  $wsgi_file = '/usr/local/share/idp-test/wsgi.py'
  $simple_flask_debug_app = @("APP")
  from flask import Flask, request
  app = Flask(__name__)
  @app.route("/")
  def root():
    return '<br />'.join(['{}={}'.format(k,v) for k,v in request.environ.items()])
  application = app
  | APP

  # BUG: need to use dirname() vs dirname
  # https://github.com/rodjek/puppet-lint/issues/937
  file {$wsgi_file.dirname():
    ensure => directory,
  }
  file {$wsgi_file:
    ensure  => file,
    content => $simple_flask_debug_app,
  }
  uwsgi::app{'idp-test':
    settings => {
      uwsgi => {
        'plugins'     => 'python3',
        'master'      => true,
        'http-socket' => '127.0.0.1:8081',
        'wsgi-file'   => $wsgi_file,
        'die-on-term' => true,
      }
    }
  }

  class {'httpd': modules => ['proxy_http', 'proxy']}
  include profile::idp::client::httpd
  ferm::service {'http-idp-test-login':
    proto => 'tcp',
    port  => 80,
  }
}
