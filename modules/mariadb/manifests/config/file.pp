# == Define mariadb::config::file
# Render a mysql config file using the given $settings hash.
#
# == Usage
#   mariadb::config::file { 'myhost':
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
# == Parameters
#   [*settings*]    - Hash of settings.  Should be of the form: { 'section_name' => {'key1' => 'value1', ... } ... }
#   [*path*]        - Path at which to create the file.  Default: /etc/mysql/conf.d/${title}.cnf
#   [*owner*]       - Owner of the file.  Default: root
#   [*group*]       - Group owner of the file.  Default: root
#   [*mode*]        - File mode.  Default: 0444
#   [*template*]    - Template to use to render the file.  Default: mariadb/my.conf.cnf.erb
#   [*ensure*]      - Either 'present' or 'absent'.  Default: present.
#
define mariadb::config::file(
    $settings,
    $path     = "/etc/mysql/conf.d/${title}.cnf",
    $owner    = 'root',
    $group    = 'root',
    $mode     = '0444',
    $template = 'mariadb/my.conf.cnf.erb',
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
