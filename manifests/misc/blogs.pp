# Wikimedia Blogs

# https://blog.wikimedia.org/
class misc::blogs::wikimedia {
    system::role { 'misc::blogs::wikimedia': description => 'blog.wikimedia.org' }

    class {'webserver::php5': ssl => true; }

    require webserver::php5-mysql,
        webserver::php5-gd

    include ::apache::mod::rpaf

    package { 'unzip':
        ensure => latest;
    }

    # apache virtual host for blog.wikimedia.org
    file {
        '/etc/apache2/sites-enabled/blog.wikimedia.org':
            path   => '/etc/apache2/sites-enabled/blog.wikimedia.org',
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///files/apache/sites/blog.wikimedia.org';
        '/etc/apache2/ports.conf':
            ensure => file,
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///files/apache/blog_ports.conf';
    }

    class { 'memcached': memcached_ip => '127.0.0.1' }
    install_certificate{ 'blog.wikimedia.org': }
    install_certificate{ 'techblog.wikimedia.org': }


    # There's not really a good reason for this to be "",
    # except that it was like that when I found it.
    # I need to pass this to varnish::logging too, so it
    # knows which varnish service to notify.
    $varnish_blog_instance_name = ''

    class { 'varnish::monitoring::ganglia': }

    # varnish cache instance for blog.wikimedia.org
    varnish::instance { 'blog':
        name            => $varnish_blog_instance_name,
        vcl             => 'blog',
        port            => 80,
        admin_port      => 6082,
        storage         => '-s malloc,1G',
        backends        => [ 'localhost' ],
        directors       => { 'backend'    => [ 'localhost' ] },
        vcl_config      => {
            'retry5xx'              => 0
        },
        backend_options => {
            'port'                  => 81,
            'connect_timeout'       => '5s',
            'first_byte_timeout'    => '35s',
            'between_bytes_timeout' => '4s',
            'max_connections'       => 256,
            'probe'                 => 'blog',
        },
    }

    # DRY this by setting defaults for varnish::logging define.
    Varnish::Logging {
        cli_args      => '-m RxRequest:^(?!PURGE\$) -D',
        instance_name => $varnish_blog_instance_name,
        monitor       => false,
    }
    # send blog access logs to udp2log instances.
    varnish::logging { 'erbium' :          listener_address => '10.64.32.135',  port => '8419' }
    varnish::logging { 'multicast_relay' : listener_address => '208.80.154.73', port => '8419' }

    include backup::host
    backup::set { 'srv-org-wikimedia': }

    ferm::rule { 'blog':
        rule => 'proto tcp dport (http https) ACCEPT;'
    }
}
