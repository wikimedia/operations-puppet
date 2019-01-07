# == Define mariadb::config::client
# Convenience wrapper for mariadb::config::file that only set a few [client] settings.
# You must set at least one of user, pass, host or port.
#
# == Usage
#   mariadb::config::client { 'myuser':
#       user => 'myser',
#       pass => 'mypass',
#   }
#
# This will render /etc/mysql/conf.d/myuser-client.cnf with the content:
#
#   [client]
#   user = myuser
#   password = mypass
#   #host =
#   #port =
#
# You can also set host and port if you like.
#
# == Parameters
#   [*user*]        - MySQL user to use for this client connection.
#   [*pass*]        - MySQL password to use for this client connection.
#   [*host*]        - MySQL host to use to for this client connection.
#   [*port*]        = MySQL port to use for this client connection.
#
#   [*path*]        - Path at which to create the file.  Default: /etc/mysql/conf.d/${title}-client.cnf
#   [*owner*]       - Owner of the file.  Default: root
#   [*group*]       - Group owner of the file.  Default: root
#   [*mode*]        - File mode.  Default: 0444
#   [*template*]    - Template to use to render the file.  Default: mariadb/my.conf.cnf.erb
#   [*ensure*]      - Either 'present' or 'absent'.  Default: present.
#
define mariadb::config::client(
    $user     = false,
    $pass     = false,
    $host     = false,
    $port     = false,
    $path     = "/etc/mysql/conf.d/${title}-client.cnf",
    $owner    = 'root',
    $group    = 'root',
    $mode     = '0444',
    $template = 'mariadb/my.conf.cnf.erb',
    $ensure   = 'present',
)
{
    if !($user or $pass or $host or $port) {
        fail('mariadb::config::client needs at least one of user, pass, host, or port to be set.')
    }

    mariadb::config::file { "${title}-client":
        ensure   => $ensure,
        settings => {
            'client' => {
                'user'     => $user,
                'password' => $pass,
                'host'     => $host,
                'port'     => $port,
            },
        },
        path     => $path,
        owner    => $owner,
        group    => $group,
        mode     => $mode,
        template => $template,
    }
}
