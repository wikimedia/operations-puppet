# Class for the ganglia frontend machine
class ganglia::web(
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
    $ganglia_ssl_chain = '/etc/ssl/localcerts/ganglia.wikimedia.org.chain.crt'
    $ganglia_ssl_key = '/etc/ssl/private/ganglia.wikimedia.org.key'
    $ssl_settings = ssl_ciphersuite('apache-2.4', 'compat')
    # Apache's docroot. Used for populating robots.txt
    $doc_root = '/var/www'

    package { [ 'php5-gd',
                'php5-mysql',
                'rrdtool',
                'librrds-perl',
                'ganglia-webfrontend',
            ]:
        ensure => $ensure,
    }

    apache::site { $ganglia_servername:
        content => template("ganglia/${ganglia_servername}.erb"),
    }

    file { '/etc/ganglia-webfrontend/conf.php':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('ganglia/conf_production.php.erb'),
        require => Package['ganglia-webfrontend'],
    }

    file { "${doc_root}/robots.txt":
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/ganglia/robots.txt',
        require => Package['ganglia-webfrontend'],
    }

    # Comment out the lines that add the 'Content-Disposition: inline; filename=...'
    # header to responses to requests for CSV or JSON data. This should be a patch
    # in the ganglia-webfrontend package, probably. -- Ori 18-Apr-2016
    exec { 'comment_out_content_disposition_headers':
        command => '/bin/sed -i "/header(\"Content-Disposition/s/^/#/" graph.php',
        onlyif  => '/bin/grep -q "^    header(\"Content-Disposition" graph.php',
        cwd     => '/usr/share/ganglia-webfrontend',
        require => Package['ganglia-webfrontend'],
    }

    # Increase the default memory limit
    file_line { 'php.ini-memory':
        line   => 'memory_limit = 768M',
        match  => '^memory_limit\s*=',
        path   => '/etc/php5/apache2/php.ini',
        notify => Class['::apache']
    }
    file_line { 'php.ini-opcache':
        line   => 'opcache.enable=1',
        path   => '/etc/php5/apache2/php.ini',
        notify => Class['::apache']
    }

    # clean up after ganglia T97637
    tidy { 'cleanup_tmp_ganglia_graph':
        path    => '/tmp',
        age     => '1w',
        recurse => true,
        matches => ['ganglia-graph*'],
        type    => 'mtime',
    }
}
