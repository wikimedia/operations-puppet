# == Class docker
#
# Requires Ubuntu 14.04 or later
#
# == Parameters:
#
# $root_dir Directory where docker.io store its graph. Passed to the Docker
#           daemon with -g. Default: /srv/docker/data
# $tmp_dir  Docker daemon temporary directory. Default: /srv/docker/tmp
#
# Both directory would need to be created beforehand.
#
class docker(
    $root_dir = "/srv/docker/data",
    $tmp_dir  = "/srv/docker/tmp",
){

    if versioncmp($::lsbdistrelease, '14.04') < 0 {
        fail('Requires Ubuntu 14.04+')
    }

    include ::docker::packages

    file { '/etc/default/docker.io':
        ensure  => present,
        content => template('docker/docker.io.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['docker.io'],
    }

}
