# This file is for all generic web server classes
# Apache, php, etc belong in here
# Specific services (racktables, etherpad) do not


class webserver::base {
    # Sysctl settings for high-load HTTP caches
    sysctl::parameters { 'high http performance':
        values => {
            # Increase the number of ephemeral ports
            'net.ipv4.ip_local_port_range' =>  [ 1024, 65535 ],

            # Recommended to increase this for 1000 BT or higher
            'net.core.netdev_max_backlog'  =>  30000,

            # Increase the queue size of new TCP connections
            'net.core.somaxconn'           => 4096,
            'net.ipv4.tcp_max_syn_backlog' => 262144,
            'net.ipv4.tcp_max_tw_buckets'  => 360000,

            # Decrease FD usage
            'net.ipv4.tcp_fin_timeout'     => 3,
            'net.ipv4.tcp_max_orphans'     => 262144,
            'net.ipv4.tcp_synack_retries'  => 2,
            'net.ipv4.tcp_syn_retries'     => 2,
        },
    }
}

# Installs a generic, static web server (lighttpd)
# with default config, which serves /var/www
class webserver::static {
    include webserver::base
    include firewall

    package { 'lighttpd':
        ensure => 'present',
    }

    $hasstatus = $::lsbdistcodename ? {
              'hardy' => false,
              default => true,
          }

    service { 'lighttpd':
        ensure    => 'running',
        hasstatus => $hasstatus,
    }

    # Monitoring
    monitor_service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }

    # Firewall
    firewall::open_port { "http-${::hostname}":
        port => 80,
    }

    firewall::open_port { "https-${::hostname}":
        port => 443,
    }
}

class webserver::php5(
    $ssl = 'false',
) {

    include webserver::base
    include ::apache
    include ::apache::mod::php5

    if $ssl == true {
        include ::apache::mod::ssl
    }

    # Monitoring
    monitor_service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}

#  Install the 'php5-mysql' package which will
#  include mysql and apache via dependencies.
class webserver::php5-mysql {

    include webserver::base

    package { 'php5-mysql':
        ensure => 'present',
        }
}

class webserver::php5-gd {

    include webserver::base

    package { 'php5-gd':
        ensure => 'present',
    }
}

# New style attempt at handling misc web servers
# - keep independent from the existing stuff


class webserver::apache {

    class config {
        # Realize virtual resources for enabling virtual hosts
        Webserver::Apache::Site <| |>
    }

    # Define: site
    #   Configures and installs an apache virtual host file using generic_vhost.erb.
    #
    # Parameters:
    #   $aliases=[]       - array of ServerAliases
    #   $ssl="false"      - if true, sets up an ssl certificate for $title
    #   $certfile=undef   - defaults to /etc/ssl/certs/${title}.pem
    #   $certkey=undef    - defaults to "/etc/ssl/private/${title}.key
    #   $docroot=undef    - defaults to: $title == 'stats.wikimedia.org', then /srv/stats.wikimedia.org
    #   $custom=[]        - custom Apache config strings to put into virtual host site file
    #   $includes=[]
    #   $server_admin="root@wikimedia.org",
    #   $access_log       - path to access log, default: /var/log/apache2/access.log
    #   $error_log        - path to error log,  default: /var/log/apache2/error.log
    #   $ensure=present
    #
    # Usage:
    #   webserver::apache::site { "mysite.wikimedia.org": aliases = ["mysite.wikimedia.com"] }
    define site(
        $aliases      = [],
        $ssl          = 'false',
        $certfile     = "/etc/ssl/certs/${title}.pem",
        $certkey      = "/etc/ssl/private/${title}.key",
        $docroot      = undef,
        $custom       = [],
        $includes     = [],
        $server_admin = 'root@wikimedia.org',
        $access_log   = "/var/log/apache2/${title}.access.log",
        $error_log    = "/var/log/apache2/${title}.error.log",
        $ensure       = 'present',
        ) {

        file { "/etc/apache2/sites-enabled/${title}":
            notify  => Service['apache2'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('apache/generic_vhost.erb'),
        }
    }

    # Default selection
    include config
    include webserver::base
}
