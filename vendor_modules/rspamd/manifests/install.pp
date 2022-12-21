# @api private 
# This class handles packages. Avoid modifying private classes.
class rspamd::install {
  assert_private()
  include rspamd
  if ($rspamd::package_manage) {
    package { 'rspamd':
      ensure => $rspamd::package_ensure,
      name   => $rspamd::package_name,
    }
  }
}
