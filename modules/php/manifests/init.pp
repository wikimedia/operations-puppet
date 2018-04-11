# == Class php
#
# Basic installation of php - only cli modules.
#
class php(
    Wmflib::Ensure $ensure = present,
    Hash $cli_config = {},
) {
    # Run-time base and some very common extensions
    $packages_list = ['cli', 'common', 'curl', 'intl', 'mysql', 'redis', 'memcached']
    # Config for the cli interpreter.
    # Please note all these parameters can be overridden
    $common_config = {
        'date.timezone'          => 'UTC',
        'default_socket_timeout' => 1,
        'display_errors'         => 'On',
        'log_errors'             => 'On',
        'include_path'           => '".:/usr/share/php"',
        'max_execution_time'     => 180,
        'memory_limit'           => '100M',
        'mysql.connect_timeout'  => 1,
        'post_max_size'          => '100M',
        'session.save_path'      => '/tmp',
        'max_upload_filesize'    => '100M'
    }

    if os_version('debian >= stretch') {
        $pkg_prefix = 'php7.0-'
        $base_config = $common_config
        $cli_conf_dir = '/etc/php/7.0'
    } else {
        $pkg_prefix = 'php5-'
        $base_config = merge($common_config, {'magic_quotes_gpc' => 'Off'})
        $cli_conf_dir = '/etc/php5'
        # We don't need php-apc on php > 5.3
        package { 'php-apc':
            ensure => absent,
        }
        # This will install libapache-mod-php5, which is somewhat undesirable
        # on any host running HHVM as an fcgi proxy
        require_package('php5-dbg')
    }

    if $ensure == 'present' {
        require_package(prefix($packages_list, $pkg_prefix))
    }

    $config = merge($base_config, $cli_config)

    file { "${cli_conf_dir}/cli/php.ini":
        ensure  => $ensure,
        content => inline_template('<%= @config.map{ |k,v| "#{k} = #{v}" }.join("\n") %>'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
