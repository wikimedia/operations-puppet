# SPDX-LicensekIdentifier: Apache-2.0
# @summary Standalone IDP class for creating an instance in WM cloud
# @param oidc_endpoint the oidc endpoint to use
# @param django_secret_key the secret key used by django
# @param oidc_key the oidc key
# @param oidc_secret the oidc secret
class profile::idp::standalone (
    Stdlib::HTTPSUrl $oidc_endpoint     = lookup('apereo_cas.production.oidc_endpoint'),
    String           $django_secret_key = lookup('profile::idp::standalone::django_secret_key'),
    String           $oidc_key          = lookup('profile::idp::standalone::oidc_key'),
    String           $oidc_secret       = lookup('profile::idp::standalone::oidc_secret'),
) {
  ensure_packages(['python3-venv'])
  # Standard stuff
  include profile::base::production
  include profile::base::firewall

  # configure database
  include profile::mariadb::packages_wmf
  class { 'mariadb::service': }
  class { 'mariadb::config':
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
  ['idp_test_login', 'django_oidc'].each |$idx, $app| {
    $wsgi_file = "/srv/${app}/wsgi.py"
    $venv_path = $wsgi_file.dirname

    file { $venv_path:
        ensure  => directory,
        recurse => remote,
        purge   => true,
        source  => "puppet:///modules/profile/idp/standalone/${app}",
    }
    exec { "create virtual environment ${venv_path}":
        command => "/usr/bin/python3 -m venv ${venv_path}",
        creates => "${venv_path}/bin/activate",
        require => [
            File[$venv_path],
            Package['python3-venv'],
        ],
    }
    exec { "install requirements to ${venv_path}":
        command => "${venv_path}/bin/pip3 install -r ${venv_path}/requirements.txt",
        creates => "${venv_path}/lib/python3.9/site-packages/social_core/__init__.py",
        require => Exec["create virtual environment ${venv_path}"],
    }
    $port = 8081 + $idx
    uwsgi::app { $app:
        settings => {
        uwsgi => {
            'plugins'     => 'python3',
            'chdir'       => $venv_path,
            'venv'        => $venv_path,
            'master'      => true,
            'http-socket' => "127.0.0.1:${port}",
            'wsgi-file'   => $wsgi_file,
            'die-on-term' => true,
        },
        },
    }
  }
  $config = {
      'ALLOWED_HOSTS'                  => ['localhost', 'sso-django-login.wmcloud.org'],
      'SECRET_KEY'                     => $django_secret_key,
      'SOCIAL_AUTH_OIDC_OIDC_ENDPOINT' => oidc_endpoint,
      'SOCIAL_AUTH_OIDC_KEY'           => $oidc_key,
      'SOCIAL_AUTH_OIDC_SECRET'        => $oidc_secret,
  }
  file { '/srv/django_oidc/oidc_auth/local-setting.py':
      ensure  => file,
      content => $config.wmflib::to_python,
      notify  => Service['uwsgi-django_oidc'],
  }

  class { 'httpd': modules => ['proxy_http', 'proxy'] }
  include profile::idp::client::httpd
  ferm::service { 'http-idp-test-login':
    proto => 'tcp',
    port  => 80,
  }
}
