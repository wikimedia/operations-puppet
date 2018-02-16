class openstack::puppet::master::encapi(
    $horizon_host,
    $mysql_host,
    $mysql_db,
    $mysql_username,
    $statsd_host,
    $statsd_prefix,
    $mysql_password,
    $labs_instance_range,
    $puppetmasters,
    $labweb_hosts,
) {
    $horizon_host_ip = ipresolve($horizon_host, 4)

    require_package('python3-pymysql',
                    'python3-statsd',
                    'python3-flask',
                    'python3-yaml')

    if os_version('debian >= jessie') {
        require_package('python-flask',
                        'python-pymysql',
                        'python-statsd',
                        'python-yaml')
    }


    file { '/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/puppet/master/encapi/labspuppetbackend.py',
    }

    # The app will check that the requesting IP is in  ALLOWED_WRITERS
    #  before writing or deleting.
    $labweb_ips = $labweb_hosts.map |$host| { ipresolve($host, 4) }
    $labweb_ips_v6 = $labweb_hosts.map |$host| { ipresolve($host, 6) }
    $allowed_writers = flatten([$labweb_ips, $labweb_ips_v6, $horizon_host_ip])

    uwsgi::app { 'labspuppetbackend':
        settings  => {
            uwsgi => {
                plugins             => 'python3',
                'wsgi-file'         => '/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py',
                callable            => 'app',
                master              => true,
                http-socket         => '0.0.0.0:8101',
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

        subscribe => File['/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py'],
    }

    # This is a GET-only front end that sits on port 8100.  We can
    #  open this up to the public even though the actual API has no
    #  auth protections.
    nginx::site { 'labspuppetbackendgetter':
        content => template('openstack/puppet/master/encapi/labspuppetbackendgetter.conf.erb'),
    }
}
