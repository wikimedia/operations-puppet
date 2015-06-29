# == Class: role::tessera
#
# tessera is a dashboarding webapp for Graphite.
# It powers <https://tessera.wikimedia.org>.
#
class role::tessera {
    include ::apache::mod::headers
    include ::apache::mod::rewrite
    include ::apache::mod::uwsgi

    include ::passwords::tessera

    class { '::tessera':
        graphite_url => 'https://graphite.wikimedia.org',
        secret_key   => $passwords::tessera::secret_key,
    }

    apache::site { 'tessera.wikimedia.org':
        content => template('apache/sites/tessera.wikimedia.org.erb'),
        require => Class['::tessera'],
    }

    monitoring::service { 'tessera':
        description   => 'tessera.wikimedia.org',
        check_command => 'check_http_url!tessera.wikimedia.org!/',
    }
}
