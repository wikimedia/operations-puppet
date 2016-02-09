# == Define: alternatives::install
#
# Debian's alternatives system uses symlinks to refer generic commands
# to a particular implementation. This Puppet resource lets you install
# a new value for a particular alternative.
#
# === Parameters
#
# [*name*]
#   Name of the symlink in the alternatives directory (e.g. 'php').
#
# [*link*]
#   Generic name of the master link (e.g. '/usr/bin/php').
#
# [*path*]
#   The path to the alternative that should be installed.
#
# [*priority*]
#   The numerical priority it should be installed at.
#
# === Examples
#
#  alternatives::install { 'php':
#    link => '/usr/bin/php',
#    path => '/usr/bin/my-special-php',
#    priority => '90',
#  }
#
define alternatives::install( $link, $path, $priority ) {
    exec { "install_alternative_${title}":
        command => "/usr/bin/update-alternatives --install ${link} ${title} ${path} ${priority}",
        unless  => "/usr/bin/update-alternatives --query ${title} | /bin/grep 'Value: ${path}'",
    }
}
