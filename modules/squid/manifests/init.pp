# SPDX-License-Identifier: Apache-2.0
# @summary This class installs Squid and configures it
# @param ensure ensurable parameter
# @param config_content content of the squid config
# @param config_source a puppet source to the squid config file
# @example
#   class { 'squid': config_source => 'puppet:///modules/foo/squid-foo.conf' }
#   class { 'squid': config_content => template('foo/squid-foo.conf.erb') }
class squid (
    Wmflib::Ensure               $ensure         = present,
    Optional[String[1]]          $config_content = undef,
    Optional[Stdlib::Filesource] $config_source  = undef,
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

    logrotate::conf { 'squid':
        ensure => $ensure,
        source => 'puppet:///modules/squid/squid-logrotate',
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
