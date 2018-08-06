define php::extension(
    Wmflib::Ensure $ensure = 'present',
    String $package_name = "php-${title}",
    Integer[0,99] $priority = 20,
    Optional[Hash] $config = undef,
    Optional[Array[Php::Sapi]] $sapis = undef,
) {
    if !defined(Class['php']) {
        fail('php::extension is not meant to be used before the php class is declared.')
    }

    $_sapis = pick($sapis, $php::sapis)
    $_config = pick($config, {'extension' => "${title}.so"})
    $title_safe  = regsubst($title, '[\W_]', '-', 'G')
    $mod_file = "${php::config_dir}/mods-available/${title_safe}.ini"
    $conf_file   = sprintf('%02d-%s.%s', $priority, $title_safe, 'ini')

    # The config file needs to be present before package installation so
    # the resulting installed link will have the correct priority, and
    # no cleanup will be needed.
    # We also add the relevant tags for allowing services to subscribe to this file
    file { $mod_file:
        ensure  => $ensure,
        content => template('php/extension.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        tag     => prefix($_sapis, 'php::config::')
    }

    if $package_name != '' {
        package{ $package_name:
            ensure  => $ensure,
            require => File[$mod_file],
            tag     => prefix($_sapis, 'php::package::')
        }
    }

    # If your provided list of PHP SAPIs is not compatible with the installed SAPIs
    # the catalog will fail to apply correctly.
    $_sapis.each |$sapi| {
        file { "${php::config_dir}/${sapi}/conf.d/${conf_file}":
            ensure => ensure_link($ensure),
            target => $mod_file,
        }
    }
}
