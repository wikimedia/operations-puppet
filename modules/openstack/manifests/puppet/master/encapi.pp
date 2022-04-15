class openstack::puppet::master::encapi(
    Stdlib::Host $mysql_host,
    String $mysql_db,
    String $mysql_username,
    String $mysql_password,
    Array[Stdlib::Fqdn] $labweb_hosts,
    Array[Stdlib::Fqdn] $openstack_controllers,
    Array[Stdlib::Fqdn] $designate_hosts,
    Array[String] $labs_instance_ranges,
    Wmflib::Ensure $ensure = present,
) {
    # for new enough python3-keystonemiddleware versions
    debian::codename::require('bullseye', '>=')

    $exposed_certs_dir = '/etc/nginx'
    $puppet_cert_pub  = "${exposed_certs_dir}/ssl/cert.pem"
    $puppet_cert_priv = "${exposed_certs_dir}/ssl/server.key"
    $puppet_cert_ca   = "${exposed_certs_dir}/ssl/ca.pem"

    base::expose_puppet_certs { $exposed_certs_dir:
        ensure          => $ensure,
        provide_private => true,
        require         => Package['nginx-common'],
    }

    if $ensure == present {
        file { $puppet_cert_ca:
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => $facts['puppet_config']['localcacert'],
        }

        # make sure that the nginx service gets notified when the certs change
        File[$puppet_cert_pub] ~> Service['nginx']
        File[$puppet_cert_priv] ~> Service['nginx']
        File[$puppet_cert_ca] ~> Service['nginx']

        ensure_packages([
            'python3-pymysql',
            'python3-flask',
            'python3-yaml'
        ])
    }

    $python_version = $::lsbdistcodename ? {
        'bullseye' => 'python3.9',
    }

    file { "/usr/local/lib/${python_version}/dist-packages/puppet-enc.py":
        ensure => stdlib::ensure($ensure, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/puppet/master/encapi/puppet-enc.py',
    }

    file {'/etc/logrotate.d/puppet-enc':
        ensure => stdlib::ensure($ensure, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack/puppet/master/puppet_enc_logrotate',
    }

    # Make sure we can write to our logfile
    file { '/var/log/puppet-enc.log':
        ensure  => stdlib::ensure($ensure, 'file'),
        owner   => 'www-data',
        group   => 'www-data',
        replace => false,
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
    uwsgi::app { 'puppet-enc':
        ensure    => $ensure,
        settings  => {
            uwsgi => {
                plugins             => 'python3',
                'wsgi-file'         => "/usr/local/lib/${python_version}/dist-packages/puppet-enc.py",
                callable            => 'app',
                master              => true,
                http-socket         => '0.0.0.0:8101',
                reload-on-exception => true,
                logto               => '/var/log/puppet-enc.log',
                env                 => [
                    "MYSQL_HOST=${mysql_host}",
                    "MYSQL_DB=${mysql_db}",
                    "MYSQL_USERNAME=${mysql_username}",
                    "MYSQL_PASSWORD=${mysql_password}",
                    "ALLOWED_WRITERS=${allowed_writers}",
                ],
            },
        },
        subscribe => File["/usr/local/lib/${python_version}/dist-packages/puppet-enc.py"],
        require   => File['/var/log/puppet-enc.log'],
    }

    nginx::site { 'default':
        ensure => absent,
        before => Nginx::Site['puppet-enc-public'],
    }

    # This is a GET-only front end that sits on port 8100.  We can
    #  open this up to the public even though the actual API has no
    #  auth protections.
    nginx::site { 'puppet-enc-public':
        ensure  => $ensure,
        content => template('openstack/puppet/master/encapi/nginx-puppet-enc-public.conf.erb'),
    }
}
