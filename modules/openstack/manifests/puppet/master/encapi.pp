class openstack::puppet::master::encapi(
    $mysql_host,
    $mysql_db,
    $mysql_username,
    $statsd_host,
    $statsd_prefix,
    $mysql_password,
    $puppetmasters,
    $labweb_hosts,
    $openstack_controllers,
    Array[Stdlib::Fqdn] $designate_hosts,
) {
    require_package('python3-pymysql',
                    'python3-statsd',
                    'python3-flask',
                    'python3-yaml',
                    'python-flask',
                    'python-pymysql',
                    'python-statsd')

    $python_version = $::lsbdistcodename ? {
        'jessie'  => 'python3.4',
        'stretch' => 'python3.5',
        'buster'  => 'python3.7',
    }

    file { "/usr/local/lib/${python_version}/dist-packages/labspuppetbackend.py":
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/puppet/master/encapi/labspuppetbackend.py',
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

    $labs_instance_ranges = $network::constants::labs_networks
    # This is a GET-only front end that sits on port 8100.  We can
    #  open this up to the public even though the actual API has no
    #  auth protections.
    nginx::site { 'labspuppetbackendgetter':
        content => template('openstack/puppet/master/encapi/labspuppetbackendgetter.conf.erb'),
    }
}
