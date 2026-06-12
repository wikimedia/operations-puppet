# SPDX-License-Identifier: Apache-2.0
# @param config Configuration file to use, if the default is not suitable
class metamonitoring::public_endpoint (
    Wmflib::Ensure       $ensure,
    String               $user,
    Stdlib::Absolutepath $status_dir,
    Stdlib::Port         $listen_port,
    Stdlib::Host         $icinga_active_host,
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

    # Directory for holding downtimes, written out by cookbook usually
    file { "${status_dir}/downtimes":
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => $user,
        group  => $user,
        mode   => '0755',
    }

    # * status_dir: used as a variable in the environment file template
    # * monitored_instances: used as a variable in the environment file template
    # the key of each entry serves as a "gist" of the entry itself
    # the concatenation of these keys is required by the script to function properly
    $monitored_instances = join(sort(metamonitoring::expected_instances().keys), ',')

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
            "ICINGA_ACTIVE_HOST=${icinga_active_host}",
          ],
        },
    }

    profile::auto_restarts::service { 'uwsgi-metamonitoring_public_endpoint': }
}
