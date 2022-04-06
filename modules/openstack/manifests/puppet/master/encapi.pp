class openstack::puppet::master::encapi(
    Stdlib::Host $mysql_host,
    String $mysql_db,
    String $mysql_username,
    String $mysql_password,
    Array[Stdlib::Fqdn] $labweb_hosts,
    Array[Stdlib::Fqdn] $openstack_controllers,
    Array[Stdlib::Fqdn] $designate_hosts,
    Array[String] $labs_instance_ranges
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

    ensure_packages([
        'python3-pymysql',
        'python3-flask',
        'python3-yaml'
    ])

    $python_version = $::lsbdistcodename ? {
        'stretch'  => 'python3.5',
        'buster'   => 'python3.7',
        'bullseye' => 'python3.9',
    }

    $service_name = debian::codename::ge('bullseye').bool2str('puppet-enc', 'labspuppetbackend')

    file { "/usr/local/lib/${python_version}/dist-packages/${service_name}.py":
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/puppet/master/encapi/puppet-enc.py',
    }

    file {'/etc/logrotate.d/puppet-enc':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack/puppet/master/puppet_enc_logrotate',
    }

    # Make sure we can write to our logfile
    file { "/var/log/${service_name}.log":
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
    uwsgi::app { $service_name:
        settings  => {
            uwsgi => {
                plugins             => 'python3',
                'wsgi-file'         => "/usr/local/lib/${python_version}/dist-packages/${service_name}.py",
                callable            => 'app',
                master              => true,
                http-socket         => '0.0.0.0:8101',
                reload-on-exception => true,
                logto               => "/var/log/${service_name}.log",
                env                 => [
                    "MYSQL_HOST=${mysql_host}",
                    "MYSQL_DB=${mysql_db}",
                    "MYSQL_USERNAME=${mysql_username}",
                    "MYSQL_PASSWORD=${mysql_password}",
                    "ALLOWED_WRITERS=${allowed_writers}",
                ],
            },
        },
        subscribe => File["/usr/local/lib/${python_version}/dist-packages/${service_name}.py"],
        require   => File["/var/log/${service_name}.log"],
    }

    $public_site_name = debian::codename::ge('bullseye').bool2str('puppet-enc-public', 'labspuppetbackendgetter')
    nginx::site { 'default': # otherwise we'll cause nginx to be installed with the default port 80 config which will conflict with apache used by the puppetmaster itself
        ensure => absent,
        before => Nginx::Site[$public_site_name],
    }

    # This is a GET-only front end that sits on port 8100.  We can
    #  open this up to the public even though the actual API has no
    #  auth protections.
    nginx::site { $public_site_name:
        content => template('openstack/puppet/master/encapi/nginx-puppet-enc-public.conf.erb'),
    }

    # make sure that the nginx service gets notified when the certs change
    File[$puppet_cert_pub] ~> Service['nginx']
    File[$puppet_cert_priv] ~> Service['nginx']
    File[$puppet_cert_ca] ~> Service['nginx']
}
