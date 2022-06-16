# SPDX-License-Identifier: Apache-2.0
define php::extension(
    Wmflib::Ensure $ensure = 'present',
    Boolean $install_packages = true,
    Boolean $versioned_packages = false,
    Hash[Wmflib::Php_version, String] $package_overrides = {},
    Integer[0,99] $priority = 20,
    Optional[Array[Wmflib::Php_version]] $versions = undef,
    Optional[Hash] $config = undef,
    Optional[Array[Php::Sapi]] $sapis = undef,
) {
    if !defined(Class['php']) {
        fail('php::extension is not meant to be used before the php class is declared.')
    }
    $_versions = pick($versions, $php::versions)
    $_sapis = pick($sapis, $php::sapis)

    # Install packages.
    # Sadly package naming in Debian for php is quite irregular,
    # so an extension can have, depending on the individual case:
    # - If the extension is for php 7.4, it will always use the
    #   php$version-$name schema
    # - If the extension is not bundled with the php source code,
    #    the name will be php-$name
    # - If the extension is bundled with the php source code, the
    #   versioned naming schema is used
    #
    # Given the general irregularity, and the possibility we will
    # change this schema again in the future, we choose to leave more
    # flexibility to the user of this class.
    if ($install_packages) {
        $actual_overrides = $package_overrides.filter |$k, $v| {$k in $_versions}
        if ($versioned_packages) {
            $version_packages = $_versions.map |$v| {{"${v}" => "php${v}-${name}"}}.reduce({}) |$m,$val| { $m.merge($val)}.merge($actual_overrides)
        } else {
            $version_packages = $_versions.map |$v| {{"${v}" => "php-${name}"}}.reduce({}) |$m,$val| { $m.merge($val)}.merge($actual_overrides)
        }
        # Now install all the packages.
        $version_packages.values.unique.each |$pkg| {
            # Get all versions that use this specific package, build tags, so we notify the right daemons.
            $all_sapi_versions = $version_packages.filter |$v,$p| {$p == $pkg}.keys.map |$version| {$_sapis.map |$sapi| {"${version}::${sapi}"}}.flatten
            package { $pkg:
                ensure => $ensure,
                tag    => prefix($all_sapi_versions, 'php::package::')
            }
        }
    }

    $_config = pick($config, {'extension' => "${title}.so"})
    $title_safe  = regsubst($title, '[\W]', '-', 'G')
    $conf_file   = sprintf('%02d-%s.%s', $priority, $title_safe, 'ini')
    $_versions.each |$version| {
        $config_dir = php::config_dir($version)
        $mod_file = "${config_dir}/mods-available/${title_safe}.ini"
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
            tag     => prefix($_sapis, "php::config::${version}::")
        }
        # Ensure the package is installed after the mod file is installed.
        if $install_packages {
            File[$mod_file] -> Package[$version_packages[$version]]
        }
        # If your provided list of PHP SAPIs is not compatible with the installed SAPIs
        # the catalog will fail to apply correctly.
        $_sapis.each |$sapi| {
            file { "${config_dir}/${sapi}/conf.d/${conf_file}":
                ensure => stdlib::ensure($ensure, 'link'),
                target => $mod_file,
            }
        }
    }
}
