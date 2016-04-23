class labspuppetbackend(
    $mysql_host,
    $mysql_db,
    $mysql_username,
    $mysql_password,
    $statsd_host,
    $statsd_prefix,
) {
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
                'wsgi-file' => "/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py",
                callable    => 'app',
                master      => true,
                http-socket => '127.0.0.1:8080',
                env         => [
                    "MYSQL_HOST=${MYSQL_HOST}",
                    "MYSQL_DB=${MYSQL_DB}",
                    "MYSQL_USERNAME=${MYSQL_USERNAME}",
                    "MYSQL_PASSWORD=${MYSQL_PASSWORD}",
                    "STATSD_HOST=${STATSD_HOST}",
                    "STATSD_PREFIX=${STATSD_PREFIX}",
                ],
            }
        },
        subscribe => File['/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py']
    }
}
