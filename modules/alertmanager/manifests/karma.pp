# SPDX-License-Identifier: Apache-2.0
# @param config Configuration file to use, if the default is not suitable
class alertmanager::karma (
    String $vhost,
    Optional[String] $config = undef,
    Stdlib::Host $listen_address = 'localhost',
    Stdlib::Port $listen_port = 19194,
    Optional[String] $auth_header = undef,
) {
    ensure_packages(['karma'])

    systemd::service { 'karma':
        ensure   => present,
        content  => init_template('karma', 'systemd_override'),
        override => true,
        restart  => true,
    }

    if $config {
        $content = $config
    } else {
        $content = template('alertmanager/karma.yml.erb')
    }

    file { '/etc/karma.yml':
        ensure       => present,
        owner        => 'root',
        group        => 'root',
        mode         => '0444',
        content      => $content,
        validate_cmd => '/usr/bin/karma --config.file % --check-config',
        notify       => Service['karma'],
    }
}
