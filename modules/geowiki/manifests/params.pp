# == Class geowiki::params
#
class geowiki::params {
    $user                   = 'stats',
    $path                   = '/srv/geowiki',
    $private_data_bare_host = 'stat1003.eqiad.wmnet',

    $scripts_path           = "${path}/scripts"
    $private_data_path      = "${path}/data-private"
    $private_data_bare_path = "${path}/data-private-bare"
    $public_data_path       = "${path}/data-public"
    $log_path                = "${path}/logs"
}
