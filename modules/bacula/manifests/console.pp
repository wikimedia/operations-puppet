# Class: bacula::console
#
# This class installs bconsole and configures it by collecting an exported
# resource from the specified director
#
# Parameters:
#   $director
#       The FQDN of the server being our director
#
# Actions:
#       Install bconsole and configure it
#
# Requires:
#
# Sample Usage:
#       class { 'bacula::console':
#           director    => 'dir.example.com',
#       }
#
class bacula::console($director) {

    package { 'bacula-console':
        ensure => installed,
    }

    File <<| tag == "bacula-console-${director}" |>>
}
