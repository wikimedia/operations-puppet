class labspuppetbackend(
    $mysql_host,
    $mysql_db,
    $mysql_username,
    $statsd_host,
    $statsd_prefix,
    $mysql_password = hiera('labspuppetbackend_mysql_password'),
) {
    require_package('python3-pymysql',
                    'python3-statsd',
                    'python3-flask',
                    'python3-yaml')


    file { '/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py':
        source => 'puppet:///modules/labspuppetbackend/labspuppetbackend.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    $horizon_host_ip = ipresolve(hiera('labs_horizon_host'), 4)
    uwsgi::app { 'labspuppetbackend':
        settings  => {
            uwsgi => {
                plugins             => 'python3',
                'wsgi-file'         => '/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py',
                callable            => 'app',
                master              => true,
                http-socket         => '0.0.0.0:8100',
                env                 => [
                    "MYSQL_HOST=${mysql_host}",
                    "MYSQL_DB=${mysql_db}",
                    "MYSQL_USERNAME=${mysql_username}",
                    "MYSQL_PASSWORD=${mysql_password}",
                    "STATSD_HOST=${statsd_host}",
                    "STATSD_PREFIX=${statsd_prefix}",
                ],
                # This next rule is actually two rules jammed together -- they have to be
                #  sequential and Puppet can't be trusted to insert them in the correct order.
                #
                # The first rule says "If the request is from the horizon host, anything goes."
                #
                # The second rule says "If this is a post, throw a 403"
                #
                # The sum effect is to allow POSTs only from horizon.
                #
                'route-remote-addr' => "^${horizon_host_ip}\$ continue:\nroute-if=equal:\${REQUEST_METHOD};POST break:403 Forbidden",
            }
        },
        subscribe => File['/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py']
    }
}
