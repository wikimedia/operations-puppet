# SPDX-License-Identifier: Apache-2.0
# @param config Configuration file to use, if the default is not suitable
class metamonitoring::public_endpoint (
    Wmflib::Ensure       $ensure,
    String               $group,
    Stdlib::Absolutepath $status_dir,
    Stdlib::Host         $listen_address,
    Stdlib::Port         $listen_port,
) {
    ensure_packages(['python3-gunicorn', 'python3-flask', 'python3-box'])

    file {
        '/usr/local/lib/o11y-metamonitoring/metamonitoring-public-endpoint.py':
            ensure => stdlib::ensure($ensure, 'file'),
            source => 'puppet:///modules/metamonitoring/metamonitoring_public_endpoint.py',
            mode   => '0555',
            notify => Service['metamonitoring_public_endpoint']
    }

    # monitored_instances: used as a variable in the environment file template
    # the key of each entry serves as a "gist" of the entry itself
    # the concatenation of these keys is required by the script to function properly
    $monitored_instances = join((metamonitoring::expected_instances()).keys, ',')

    file { '/etc/default/metamonitoring_public_endpoint':
        ensure  => stdlib::ensure($ensure, 'file'),
        content => template('metamonitoring/metamonitoring_public_endpoint.env.erb'),
        mode    => '0444',
        notify  => Service['metamonitoring_public_endpoint']
    }

    systemd::service { 'metamonitoring_public_endpoint':
        ensure  => $ensure,
        content => init_template('metamonitoring_public_endpoint', 'systemd'),
        restart => true,
    }
}
