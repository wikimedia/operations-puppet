class openstack::puppet::master::encapi(
    Stdlib::Host                         $mysql_host,
    String[1]                            $mysql_db,
    String[1]                            $mysql_username,
    String[1]                            $mysql_password,
    String[1]                            $acme_certname,
    Stdlib::HTTPSUrl                     $keystone_api_url,
    String[1]                            $token_validator_username,
    String[1]                            $token_validator_password,
    String[1]                            $token_validator_project,
    Array[Stdlib::Fqdn]                  $labweb_hosts,
    Array[Stdlib::Fqdn]                  $openstack_controllers,
    Array[Stdlib::Fqdn]                  $designate_hosts,
    Array[Stdlib::IP::Address::V4::CIDR] $labs_instance_ranges,
    Wmflib::Ensure                       $ensure = present,
) {
    # for new enough python3-keystonemiddleware versions
    debian::codename::require('bullseye', '>=')

    base::expose_puppet_certs { '/etc/nginx':
        ensure => absent,
    }

    acme_chief::cert { $acme_certname:
        ensure     => $ensure,
        puppet_svc => 'nginx',
    }

    if $ensure == 'present' {
        ensure_packages([
            'python3-flask',
            'python3-flask-keystone',  # this one is built and maintained by us
            'python3-oslo.context',
            'python3-oslo.policy',
            'python3-pymysql',
            'python3-yaml',
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
    $allowed_writers = ($labweb_hosts + $designate_hosts + $openstack_controllers).reduce([]) |Array $accumulate, Stdlib::Fqdn $host| {
        $accumulate + [
            ipresolve($host, 4),
            ipresolve($host, 6),
        ]
    }

    file { '/etc/puppet-enc-api':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
    }

    file { '/etc/puppet-enc-api/config.ini':
        content   => template('openstack/puppet/master/encapi/config.ini.erb'),
        owner     => 'root',
        group     => 'www-data',
        mode      => '0440',
        show_diff => false,
        notify    => Uwsgi::App['puppet-enc'],
    }

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
                socket              => '/run/uwsgi/puppet-enc.sock',
                reload-on-exception => true,
                logto               => '/var/log/puppet-enc.log',
            },
        },
        subscribe => File["/usr/local/lib/${python_version}/dist-packages/puppet-enc.py"],
        require   => File['/var/log/puppet-enc.log'],
    }

    nginx::site { 'default':
        ensure => absent,
        before => Nginx::Site['puppet-enc-public'],
    }

    $ssl_settings  = ssl_ciphersuite('nginx', 'strong')

    nginx::site { 'puppet-enc':
        ensure  => $ensure,
        content => template('openstack/puppet/master/encapi/nginx-puppet-enc.conf.erb'),
    }

    # This is a GET-only front end that sits on port 8100.  We can
    #  open this up to the public even though the actual API has no
    #  auth protections.
    nginx::site { 'puppet-enc-public':
        ensure  => $ensure,
        content => template('openstack/puppet/master/encapi/nginx-puppet-enc-public.conf.erb'),
    }
}
