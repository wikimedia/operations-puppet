# == Define mysql::config::client
# Convenience wrapper for mysql::config::file that only set a few [client] settings.
#
# == Usage
#   mysql::config::client { 'myuser':
#       user => 'myser',
#       pass => 'mypass',
#   }
#
# This will render /etc/mysql/conf.d/myuser-client.cnf with the content:
#
#   [client]
#   user = myuser
#   password = mypass
#   #host=
#   #port=
#
# You can also set host and port if you like.
#
define mysql::config::client(
    $user     = false,
    $pass     = false,
    $host     = false,
    $port     = false,
    $path     = "/etc/mysql/conf.d/${title}.cnf",
    $owner    = 'root',
    $group    = 'root',
    $mode     = '0444',
    $template = 'mysql/my.conf.cnf.erb',
    $ensure   = 'present',
)
{
    if !($user or $pass or $host or $port) {
        fail('mysql::config::client needs at least one of user, pass, host, or port to be set.')
    }

    mysql::config::file { "${title}-client":
        ensure     => $ensure,
        settings => {
            'client' => {
                'user'     => $user,
                'password' => $pass,
                'host'     => $host,
                'port'     => $port,
            },
        },
        path       => $path,
        owner      => $owner,
        group      => $group,
        mode       => $mode,
        template   => $template,
    }
}
