# SPDX-License-Identifier: Apache-2.0
# @summary This class installs Squid and configures it
# @param ensure ensurable parameter
# @param config_content content of the squid config
# @param logrotate_frequency set the logrotate frequency
# @param logrotate_days number of days to keep log files
# @param config_source a puppet source to the squid config file
# @example
#   class { 'squid': config_source => 'puppet:///modules/foo/squid-foo.conf' }
#   class { 'squid': config_content => template('foo/squid-foo.conf.erb') }
class squid (
    Wmflib::Ensure               $ensure              = present,
    Logrotate::Frequency         $logrotate_frequency = 'daily',
    Integer[1]                   $logrotate_days      = 2,
    Optional[String[1]]          $config_content      = undef,
    Optional[Stdlib::Filesource] $config_source       = undef,
) {
    if $ensure == 'present' and $config_content =~ Undef and $config_source =~ Undef {
        fail('if $ensure is present you most also set $config_content or $config_source')
    }

    package { 'squid':
        ensure => $ensure,
    }

    file {
        default:
            mode  => '0444',
            owner => 'root',
            group => 'root';
        '/etc/squid':
            ensure  => stdlib::ensure($ensure, 'directory');
        '/etc/squid/squid.conf':
            ensure  => stdlib::ensure($ensure, 'file'),
            source  => $config_source,
            content => $config_content,
            notify  => Service['squid'];
    }

    $rotate = $logrotate_frequency ? {
        'hourly' => $logrotate_days * 24,
        default  => $logrotate_days,
    }
    logrotate::rule { 'squid':
        ensure      => $ensure,
        file_glob   => '/var/log/squid/*.log',
        compress    => true,
        frequency   => $logrotate_frequency,
        rotate      => $rotate,
        missing_ok  => true,
        size        => '300M',
        no_create   => true,
        post_rotate => ['test ! -e /var/run/squid.pid || /usr/sbin/squid -k rotate'],
    }

    systemd::unit { 'squid':
        content  => "[Service]\nLimitNOFILE=32768\n",
        override => true,
        restart  => true,
    }
    service { 'squid':
        ensure  => stdlib::ensure($ensure, 'service'),
        require => Systemd::Unit['squid'],
    }
}
