# === Class docker::configuration
#
# sets up the daemon.json file for the docker daemon.
#
# === Parameters
#
# [*settings*] The settings of the docker daemon, as a hash
#
# [*location*] The path on the filesystem for the daemon.json file.
#              Defaults to /etc/docker/daemon.json
#
class docker::configuration(
    $settings,
    $directory='/etc/docker',
    $location='/etc/docker/daemon.json',
) {
    file { $directory:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }
    file { $location:
        ensure  => present,
        content => ordered_json($settings),
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
    }
}
