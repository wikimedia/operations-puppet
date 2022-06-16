# SPDX-License-Identifier: Apache-2.0
# == Class php
#
# Basic installation of php - only cli modules.
#
class php(
    Array[Wmflib::Php_version] $versions = [],
    Wmflib::Ensure $ensure             = present,
    Array[Php::Sapi] $sapis            = ['cli'],
    Hash $config_by_sapi               = {},
    Hash $extensions                   = {}
) {
    debian::codename::require::min('stretch')

    # Basic configuration parameters.
    # Please note all these parameters can be overridden
    $base_config = {
        'date'                   => {
            'timezone' => 'UTC',
        },
        'default_socket_timeout' => 1,
        'display_errors'         => 'On',
        'log_errors'             => 'On',
        'include_path'           => '".:/usr/share/php"',
        'max_execution_time'     => 180,
        'memory_limit'           => '100M',
        'mysql'                  => {
            'connect_timeout' => 1,
        },
        'post_max_size'         => '100M',
        'session'               => {
            'save_path' => '/tmp',
        },
        'upload_max_filesize'   => '100M',
    }



    # We need php-common everywhere
    $versions.each |$version| {
        ensure_packages(["php${version}-common", "php${version}-opcache"])
        $config_dir = php::config_dir($version)

        $package_by_sapi = {
            'cli'     => "php${version}-cli",
            'fpm'     => "php${version}-fpm",
            'apache2' => "libapache2-mod-php${version}",
        }


        # Let's install the packages and configure PHP for each of the selected
        # SAPIs. Please note that if you want to configure php-fpm you will have
        # to declare the php::fpm class (and possibly some php::fpm::pool defines
        # too).
        $sapis.each |$sapi| {
            package { $package_by_sapi[$sapi]:
                ensure => $ensure,
            }
            # The directory gets managed by us actively.
            # This means that rogue configurations added by
            # packages will be actively removed.
            file { "${config_dir}/${sapi}/conf.d":
                ensure  => stdlib::ensure($ensure, 'directory'),
                owner   => 'root',
                group   => 'root',
                mode    => '0755',
                recurse => true,
                purge   => true
            }
            # Merge the basic configuration with the sapi-specific one, if present.
            file { "${config_dir}/${sapi}/php.ini":
                ensure  => $ensure,
                content => wmflib::php_ini($base_config, pick($config_by_sapi[$sapi], {})),
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                tag     => "php::config::${sapi}",
            }
        }
    }


    # Configure the builtin extensions
    class { '::php::default_extensions': }

    # Install and configure the extensions provided by the user
    $ext_defaults = {'sapis' => $sapis}
    $extensions.each |$ext_name,$ext_params| {
        $parameters = merge($ext_defaults, $ext_params)
        php::extension { $ext_name:
            * => $parameters
        }
    }
}
