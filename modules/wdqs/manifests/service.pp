# == Class: wdqs::service
#
# Provisions WDQS service package
#
# == Parameters:
# - $package_dir:  Directory where the service should be installed.
# Should have enough space to hold the database (>50G)
# - $version: Version of the service to install
# - $username: Username owning the service
#
class wdqs::service(
    $package_dir,
    $version,
    $username,
) {
    # Horrible hack, find better way?
    exec { 'download_package':
        command => "/usr/local/sbin/install_wdqs.sh ${version} ${package_dir}",
        cwd     => $package_dir,
        creates => "${package_dir}/service-${version}",
        require => [
          Package['maven'],
          File['/usr/local/sbin/install_wdqs.sh']
        ],
    }

    file { '/usr/local/sbin/install_wdqs.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/wdqs/install_wdqs.sh',
        mode   => '0755',
    }

    file { "${package_dir}/service-${version}":
        owner   => $username,
        group   => 'wikidev',
        mode    => '0775',
        require => Exec['download_package'],
    }
}
