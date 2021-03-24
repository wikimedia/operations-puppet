class openstack::puppet::master::encapi(
    String $mysql_host,
    String $mysql_db,
    String $mysql_username,
    String $statsd_host,
    String $statsd_prefix,
    String $mysql_password,
    Hash[Stdlib::Fqdn, Puppetmaster::Backends] $puppetmasters,
    Array[Stdlib::Fqdn] $labweb_hosts,
    Array[Stdlib::Fqdn] $openstack_controllers,
    Array[Stdlib::Fqdn] $designate_hosts,
    Array[String] $labs_instance_ranges = $network::constants::labs_networks
) {
    $exposed_certs_dir = '/etc/nginx'
    $puppet_cert_pub  = "${exposed_certs_dir}/ssl/cert.pem"
    $puppet_cert_priv = "${exposed_certs_dir}/ssl/server.key"
    $puppet_cert_ca   = "${exposed_certs_dir}/ssl/ca.pem"
    base::expose_puppet_certs { $exposed_certs_dir:
      provide_private => true,
    }
    file { $puppet_cert_ca:
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => $facts['puppet_config']['localcacert'],
    }

    ensure_packages(['python3-pymysql',
                    'python3-statsd',
                    'python3-flask',
                    'python3-yaml',
                    'python-flask',
                    'python-pymysql',
                    'python-statsd'])

    $python_version = $::lsbdistcodename ? {
        'stretch' => 'python3.5',
        'buster'  => 'python3.7',
    }

    file { "/usr/local/lib/${python_version}/dist-packages/labspuppetbackend.py":
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/puppet/master/encapi/labspuppetbackend.py',
    }

    # Make sure we can write to our logfile
    file { '/var/log/labspuppetbackend.log':
        owner => 'www-data',
        group => 'www-data',
    }

    # The app will check that the requesting IP is in  ALLOWED_WRITERS
    #  before writing or deleting.
    $labweb_ips = $labweb_hosts.map |$host| { ipresolve($host, 4) }
    $labweb_ips_v6 = $labweb_hosts.map |$host| { ipresolve($host, 6) }
    $designate_ips = $designate_hosts.map |$host| { ipresolve($host, 4) }
    $designate_ips_v6 = $designate_hosts.map |$host| { ipresolve($host, 6) }
    $openstack_controller_ips = $openstack_controllers.map |$host| { ipresolve($host, 4) }
    $openstack_controller_ips_v6 = $openstack_controllers.map |$host| { ipresolve($host, 6) }
    $allowed_writers = join(flatten([
      $labweb_ips,
      $labweb_ips_v6,
      $designate_ips,
      $designate_ips_v6,
      $openstack_controller_ips,
      $openstack_controller_ips_v6,]),',')

    # We override service_settings because the default includes autoload
    #  which insists on using python2
    uwsgi::app { 'labspuppetbackend':
        settings  => {
            uwsgi => {
                plugins             => 'python3',
                'wsgi-file'         => "/usr/local/lib/${python_version}/dist-packages/labspuppetbackend.py",
                callable            => 'app',
                master              => true,
                http-socket         => '0.0.0.0:8101',
                reload-on-exception => true,
                logto               => '/var/log/labspuppetbackend.log',
                env                 => [
                    "MYSQL_HOST=${mysql_host}",
                    "MYSQL_DB=${mysql_db}",
                    "MYSQL_USERNAME=${mysql_username}",
                    "MYSQL_PASSWORD=${mysql_password}",
                    "STATSD_HOST=${statsd_host}",
                    "STATSD_PREFIX=${statsd_prefix}",
                    "ALLOWED_WRITERS=${allowed_writers}",
                ],
            },
        },
        subscribe => File["/usr/local/lib/${python_version}/dist-packages/labspuppetbackend.py"],
    }

    nginx::site { 'default': # otherwise we'll cause nginx to be installed with the default port 80 config which will conflict with apache used by the puppetmaster itself
        ensure => absent,
        before => Nginx::Site['labspuppetbackendgetter'],
    }

    # This is a GET-only front end that sits on port 8100.  We can
    #  open this up to the public even though the actual API has no
    #  auth protections.
    nginx::site { 'labspuppetbackendgetter':
        content => template('openstack/puppet/master/encapi/labspuppetbackendgetter.conf.erb'),
    }

    # make sure that the nginx service gets notified when the certs change
    File[$puppet_cert_pub] ~> Service['nginx']
    File[$puppet_cert_priv] ~> Service['nginx']
    File[$puppet_cert_ca] ~> Service['nginx']
}
