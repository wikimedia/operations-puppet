# == Class geowiki
# Clones analytics/geowiki python scripts
#
class geowiki(
    $private_data_bare_host,
    $user                   = 'stats',
    $path                   = '/srv/geowiki',
) {
    $scripts_path           = "${path}/scripts"
    $private_data_path      = "${path}/data-private"
    $private_data_bare_path = "${path}/data-private-bare"
    $public_data_path       = "${path}/data-public"
    $log_path               = "${path}/logs"

    file { $path:
        ensure => 'directory',
    }

    git::clone { 'geowiki-scripts':
        ensure    => 'latest',
        directory => $scripts_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/geowiki.git',
        owner     => $user,
        group     => $user,
        require   => File[$path],
    }
}
