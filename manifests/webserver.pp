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
    include php5::apache2packages

    if $ssl == true {
        apache_module { 'ssl':
            name => 'ssl' }
    }

    service { 'apache2':
        ensure    => running,
        require   => Package['apache2-mpm-prefork'],
        subscribe => Package['libapache2-mod-php5'],
    }

    # ensure default site is removed
    apache_site { '000-default':
        ensure => 'absent',
        name   => '000-default',
    }

    apache_site { '000-default-ssl':
        ensure => 'absent',
        name   => '000-default-ssl',
    }

    # Monitoring
    monitor_service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}

class webserver::modproxy {

    include webserver::base

    package { 'libapache2-mod-proxy-html':
        ensure => 'present',
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

#  Install the 'apache2' package
class webserver::apache2 {

    include webserver::base

    package { 'apache2':
        ensure => 'present',
    }

    # ensure default site is removed
    apache_site { '000-default':
        ensure => 'absent',
        name   => '000-default',
    }
    apache_site { '000-default-ssl':
        ensure => 'absent',
        name   => '000-default-ssl',
    }
}

class webserver::apache2::rpaf {
    # NOTE: rpaf.conf defaults to just 127.0.01 - may need to
    # modify to include squid/varnish/nginx ranges depending
    # on use.
    package { 'libapache2-mod-rpaf':
        ensure => 'present',
    }
    apache_module { 'rpaf':
        name    => 'rpaf',
        require => Package['libapache2-mod-rpaf'],
    }
}


# New style attempt at handling misc web servers
# - keep independent from the existing stuff


class webserver::apache {
    class packages(
        $mpm = 'prefork'
) {
    if ! defined( Package['apache2'] ) {
        package { 'apache2':
            ensure => 'present',
        }
    }

    if ! defined( Package["apache2-mpm-${mpm}"] ) {
        package { "apache2-mpm-${mpm}":
            ensure => 'present',
        }

    }
}
    # TODO: documentation of parameters
    define module {
        Class['webserver::apache::packages'] -> Webserver::Apache::Module[$title] -> Class['webserver::apache::config']

        $packagename = $::operatingsystem ? {
            Ubuntu => $title ? {
                perl => 'libapache2-mod-perl2',

                actions         => undef,
                alias           => undef,
                apreq           => undef,
                asis            => undef,
                auth_basic      => undef,
                auth_digest     => undef,
                authn_alias     => undef,
                authn_anon      => undef,
                authn_dbd       => undef,
                authn_dbm       => undef,
                authn_default   => undef,
                authn_file      => undef,
                authnz_ldap     => undef,
                authz_dbm       => undef,
                authz_default   => undef,
                authz_groupfile => undef,
                authz_host      => undef,
                authz_owner     => undef,
                authz_user      => undef,
                autoindex       => undef,
                cache           => undef,
                cern_meta       => undef,
                cgi             => undef,
                cgid            => undef,
                charset_lite    => undef,
                dav             => undef,
                dav_fs          => undef,
                dav_lock        => undef,
                dbd             => undef,
                deflate         => undef,
                dir             => undef,
                disk_cache      => undef,
                dump_io         => undef,
                env             => undef,
                expires         => undef,
                ext_filter      => undef,
                file_cache      => undef,
                filter          => undef,
                headers         => undef,
                ident           => undef,
                imagemap        => undef,
                include         => undef,
                info            => undef,
                ldap            => undef,
                log_forensic    => undef,
                mem_cache       => undef,
                mime            => undef,
                mime_magic      => undef,
                negotiation     => undef,
                perl            => undef,
                perl2           => undef,
                proxy           => undef,
                proxy_ajp       => undef,
                proxy_balancer  => undef,
                proxy_connect   => undef,
                proxy_ftp       => undef,
                proxy_http      => undef,
                proxy_scgi      => undef,
                reqtimeout      => undef,
                rewrite         => undef,
                setenvif        => undef,
                speling         => undef,
                ssl             => undef,
                status          => undef,
                substitute      => undef,
                suexec          => undef,
                unique_id       => undef,
                userdir         => undef,
                usertrack       => undef,
                version         => undef,
                vhost_alias     => undef,

                default => "libapache2-mod-${title}"
            },
            default => "libapache2-mod-${title}"
        }

        if $packagename {
            package { $packagename:
                ensure => present;
            }
        }
        File {
            require   => $packagename ? {
                undef   => undef,
                default => Package[$packagename]
            },
            notify => Class['webserver::apache::service'],
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }
        file { "/etc/apache2/mods-available/${title}.conf":
            ensure => 'present',
        }

        file { "/etc/apache2/mods-available/${title}.load":
            ensure => 'present',
        }

        file { "/etc/apache2/mods-enabled/${title}.conf":
            ensure => 'link',
            target => "../mods-available/${title}.conf",
        }

        file { "/etc/apache2/mods-enabled/${title}.load":
            ensure => 'link',
            target => "../mods-available/${title}.load",
        }
    }

    class config {
        # Realize virtual resources for Apache modules
        Webserver::Apache::Module <| |>

        # Realize virtual resources for enabling virtual hosts
        Webserver::Apache::Site <| |>
    }

    class service {
        service{ 'apache2':
            ensure => 'running',
        }
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

        Class['webserver::apache::packages'] -> Webserver::Apache::Site[$title] -> Class['webserver::apache::service']

        if $ssl in [ 'true', 'only', 'redirected' ] {
            webserver::apache::module { 'ssl': }
        }

        file { "/etc/apache2/sites-available/${title}":
            notify  => Class['webserver::apache::service'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('apache/generic_vhost.erb'),
        }
        $enabled_symlink_ensure = $ensure ? {
            absent => 'absent',
            default => 'link'
        }
        file { "/etc/apache2/sites-enabled/${title}":
            ensure => $enabled_symlink_ensure,
            target => "/etc/apache2/sites-available/${title}",
            notify => Class['webserver::apache::service'],
        }
    }

    # Default selection
    include packages
    include config
    include service
    include webserver::base
}
