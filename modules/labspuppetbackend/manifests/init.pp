class labspuppetbackend(
    $mysql_host,
    $mysql_db,
    $mysql_username,
    $mysql_password,
    $statsd_host,
    $statsd_prefix,
) {
    require_package('python3-pymysql', 'python3-statsd', 'python3-flask', 'python3-sqlalchemy')

    file { '/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py':
        source => 'puppet:///modules/labspuppetbackend/labspuppetbackend.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    uwsgi::app { 'labspuppetbackend':
        settings  => {
            uwsgi => {
                plugins     => 'python3',
                'wsgi-file' => '/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py',
                callable    => 'app',
                master      => true,
                http-socket => "${::ipaddress}:8100",
                env         => [
                    "MYSQL_HOST=${mysql_host}",
                    "MYSQL_DB=${mysql_db}",
                    "MYSQL_USERNAME=${mysql_username}",
                    "MYSQL_PASSWORD=${mysql_password}",
                    "STATSD_HOST=${statsd_host}",
                    "STATSD_PREFIX=${statsd_prefix}",
                ],
            }
        },
        subscribe => File['/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py']
    }
}
