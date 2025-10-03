# SPDX-License-Identifier: Apache-2.0
# @param config Configuration file to use, if the default is not suitable
class metamonitoring::public_endpoint (
    Wmflib::Ensure       $ensure,
    String               $user,
    Stdlib::Absolutepath $status_dir,
    Stdlib::Port         $listen_port,
) {
    ensure_packages(['python3-flask', 'python3-box'])

    file {
        '/usr/local/lib/o11y-metamonitoring/metamonitoring_public_endpoint.py':
            ensure => stdlib::ensure($ensure, 'file'),
            source => 'puppet:///modules/metamonitoring/metamonitoring_public_endpoint.py',
            mode   => '0555',
            notify => Service::Uwsgi['metamonitoring_public_endpoint']
    }

    file {
        '/usr/local/lib/o11y-metamonitoring/metamonitoring-public-endpoint-wsgi.py':
            ensure => stdlib::ensure($ensure, 'file'),
            source => 'puppet:///modules/metamonitoring/metamonitoring_public_endpoint-wsgi.py',
            mode   => '0555',
            notify => Service::Uwsgi['metamonitoring_public_endpoint']
    }

    # * status_dir: used as a variable in the environment file template
    # * monitored_instances: used as a variable in the environment file template
    # the key of each entry serves as a "gist" of the entry itself
    # the concatenation of these keys is required by the script to function properly
    $monitored_instances = join((metamonitoring::expected_instances()).keys, ',')

    file { '/etc/default/metamonitoring_public_endpoint':
        ensure  => 'absent',
        content => template('metamonitoring/metamonitoring_public_endpoint.env.erb'),
        mode    => '0444',
        notify  => Service::Uwsgi['metamonitoring_public_endpoint']
    }

    service::uwsgi { 'metamonitoring_public_endpoint':
        ensure             => $ensure,
        port               => $listen_port,
        systemd_user       => $user,
        systemd_group      => $user,
        icinga_check       => false,
        add_logging_config => false,
        config             => {
          'wsgi-file'        => '/usr/local/lib/o11y-metamonitoring/metamonitoring-public-endpoint-wsgi.py',
          'chdir'            => '/usr/local/lib/o11y-metamonitoring',
          'processes'        => 4,
          'log-stdout'       => true,
          'catch-exceptions' => true,
          'env'              => [
            'LOG_LEVEL=info',
            "MONITORED_INSTANCES=${monitored_instances}",
            "STATUS_DIR=${status_dir}",
          ],
        },
    }

}
