# Class: rspamd::repo
# ===========================
#
# This class adds a package repo to your system's package manager.
#
# So far supported are:
# 
# * Debian/Ubuntu (adds {rspamd::repo::apt_stable})
#
# @summary this class manages the rspamd.com package repository
# 
# @example
#   include rspamd::repo
#
# @param baseurl  use a different repo url instead of rspamd.com upstream repo
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
class rspamd::repo {
  assert_private()
  include rspamd
  if($rspamd::manage_package_repo) {
    case $::osfamily {
      'Debian': {
        class { 'rspamd::repo::apt_stable': }
      }
      default: {
        fail("Unsupported managed repository for osfamily: ${::osfamily}, operatingsystem: ${::operatingsystem},\
module ${module_name} currently only supports managing repos for osfamily Debian")
      }
    }
  }
}
