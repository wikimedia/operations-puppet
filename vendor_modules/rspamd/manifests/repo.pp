# @summary Manages the rspamd.com package repository
# 
# @example
#   include rspamd::repo
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
class rspamd::repo {
  assert_private()
  include rspamd

  if ($rspamd::manage_package_repo) {
    case $facts['os']['family'] {
      'Debian': {
        class { 'rspamd::repo::apt_stable': }
      }
      'RedHat': {
        class { 'rspamd::repo::rpm_stable': }
      }
      default: {
        fail("Repository management is unsupported in module ${module_name} for this operating system: ${facts['os']['family']}, ${facts['os']['name']}") # lint:ignore:140chars
      }
    }
  }
}
