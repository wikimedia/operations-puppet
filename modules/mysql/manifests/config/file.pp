# == Define mysql::config::file
# Render a mysql config file using the given $settings hash.
#
# == Usage
#   mysql::config::file { 'myhost':
#       'settings' => {
#           'client' => {
#               'host' => 'myhost.example.org',
#               'port' => 3307,
#           },
#       },
#   }
#
# This will render /etc/mysql/conf.d/myhost.cnf with the content:
#
#   [client]
#   host = myhost.example.org
#   port = 3307
#
# You could then use this file with the mysql CLI by doing:
#   mysql --defaults-extra-file=/etc/mysql/conf.d/myhost.cnf
#
define mysql::config::file(
    $settings,
    $path     = "/etc/mysql/conf.d/${title}.cnf",
    $owner    = 'root',
    $group    = 'root',
    $mode     = '0444',
    $template = 'mysql/my.conf.cnf.erb',
    $ensure   = 'present',
)
{
    file { $path:
        ensure  => $ensure,
        owner   => $owner,
        group   => $group,
        mode    => $mode,
        content => template($template),
    }
}
