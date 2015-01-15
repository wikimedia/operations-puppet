# Class for the ganglia frontend machine
class ganglia_new::web(
                    $ensure='present',
                    $rrdcached_socket,
                    $gmetad_root,
) {
    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::ssl
    include ::apache::mod::rewrite

    $ganglia_servername = 'ganglia.wikimedia.org'
    $ganglia_serveralias = 'uranium.wikimedia.org'
    $ganglia_webdir = '/usr/share/ganglia-webfrontend'
    $ganglia_ssl_cert = '/etc/ssl/localcerts/ganglia.wikimedia.org.crt'
    $ganglia_ssl_key = '/etc/ssl/private/ganglia.wikimedia.org.key'
    $ssl_settings = ssl_ciphersuite('apache-2.4', 'compat')

    package { [ 'php5-gd',
                'php5-mysql',
                'rrdtool',
                'librrds-perl',
                'ganglia-webfrontend',
            ]:
        ensure => $ensure,
    }

    apache::site { $ganglia_servername:
        content => template("ganglia_new/${ganglia_servername}.erb"),
    }

    file { '/etc/ganglia-webfrontend/conf.php':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('ganglia_new/conf_production.php.erb'),
        require => Package['ganglia-webfrontend'],
    }
}
