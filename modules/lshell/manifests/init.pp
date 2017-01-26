# Limited shell environment
#
#  * Anything that allows shelling out escapes
#  * This is not a full shell replacment
#  * Combine with @shell_override in nslcd.conf.erb
#
# === Parameters
#
# [*$allowed_cmds*]
#  Whitelist of allowed interactive shell commands
#  No specified commands will result in permissive
#
# [*$allowed_cmd_path*]
#  Whitelist of all commands in an array of paths
#
# [*$forbidden*]
#  Invalid characters
#
# [*$banner*]
#  Display text upon login
#
# [*$overssh*]
#  Noninteractive shell commands allowed
#
# [*$timer*]
#  Session duration length allowed
#
# [*$path]
#  Array of paths user is allowed to interact with
#
# [*$prompt]
#  Shell prompt
#

class lshell (
    $allowed_cmds     = [],
    $allowed_cmd_path = [],
    $banner           = 'This is a limited shell.',
    $overssh          = [],
    $timer            = 86400,
    $path             = ['/home'],
    $prompt           = '%u',
    $exempt_grps      = ['ops'],
) {

    # allowed_cmd_paths with permissive allowed_cmds
    # is disingenious as it won't actually restrict
    if empty($allowed_cmds) and !empty($allowed_cmd_path){
        fail('allowed_cmd_path will have no effect')
    }

    package { 'lshell':
        ensure => present,
    }

    file { '/etc/lshell.conf':
        content => template('lshell/lshell.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
