
# Class: profile::birdlg::lg_frontend
#
# This profile installs all the bird-lg frontend related parts as WMF requires it
#
# Actions:
#       Deploy bird-lg
#       Install uwsgi
#       Install apache
#
# Requires:
#
# Sample Usage:
#       include profile::birdlg::lg_backend


class profile::birdlg::lg_frontend(
  $active_server = hiera('profile::birdlg::active_server', 'netmon1002.wikimedia.org'),
  $domain = hiera('profile::birdlg::domain', 'lg.wikimedia.org')
  ){
  # lint:ignore:wmf_styleguide
    include ::apache
    include ::apache::mod::headers
    include ::apache::mod::proxy_http
    include ::apache::mod::proxy
    include ::apache::mod::rewrite
    include ::apache::mod::ssl
    include ::apache::mod::wsgi
  # lint:endignore

  include passwords::birdlg
  $secret_key = $passwords::birdlg::secret_key

  class { 'birdlg::lg_frontend':
      secret_key => $secret_key,
      domain     => $domain,
  }

  $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

  apache::site { 'lg.wikimedia.org':
      content => template('profile/birdlg/lg.wikimedia.org.erb'),
  }

  letsencrypt::cert::integrated { 'birdlg':
      subjects   => 'lg.wikimedia.org',
      puppet_svc => 'apache2',
      system_svc => 'apache2',
      require    => Class['apache::mod::ssl'],
  }

  if $active_server == $::fqdn {
        $monitoring_ensure = 'present'
    } else {
        $monitoring_ensure = 'absent'
    }

    monitoring::service { 'birdlg-ssl':
        ensure        => $monitoring_ensure,
        description   => 'BirdLG SSL',
        check_command => 'check_ssl_http_letsencrypt!lg.wikimedia.org',
    }

    monitoring::service { 'birdlg-https':
        ensure        => $monitoring_ensure,
        description   => 'BirdLG HTTPS',
        check_command => 'check_https_url!lg.wikimedia.org!https://lg.wikimedia.org',
    }


}
