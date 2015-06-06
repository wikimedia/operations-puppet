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
        command => "/usr/bin/mvn org.apache.maven.plugins:maven-dependency-plugin:2.10:unpack -Dartifact=org.wikidata.query.rdf:service:${version}:zip:dist -DoutputDirectory=${package_dir} -Dtransitive=false -Dproject.basedir=/tmp",
        cwd     => '/tmp',
        creates => "${package_dir}/service-${version}",
        require => Package['maven'],
        before  => File['/tmp/target'],
    }

    file { '/tmp/target':
        ensure => absent,
        force  => true,
    }

    file { "${package_dir}/service-${version}":
        owner   => $username,
        group   => 'wikidev',
        mode    => 0775,
        require => Exec['download_package'],
    }
}
