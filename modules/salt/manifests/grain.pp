# == Define: salt::grain
#
# Set or remove a grain value.
#
# === Parameters
#
# [*grain*]
#   The name of the grain. For example, 'deployment-target'.
#   Defaults to the resource title.
#
# [*value*]
#   Value to set or remove from grain.
#
# [*ensure*]
#   If 'present', adds value to grain. If 'absent', removes it.
#   Defaults to 'present'.
#
# === Examples
#
#  salt::grain { 'deployment_target':
#    value => 'parsoid',
#  }
#
define salt::grain(
  $value,
  $grain  = $title,
  $ensure = present,
) {
  case $ensure {
    'absent': {
        exec { "/usr/local/sbin/grain-ensure remove ${grain} ${value}":
          onlyif  => "/usr/local/sbin/grain-ensure contains ${grain} ${value}",
          require => File['/usr/local/sbin/grain-ensure'],
        }
    }
    'present': {
        exec { "/usr/local/sbin/grain-ensure add ${grain} ${value}":
          unless  => "/usr/local/sbin/grain-ensure contains ${grain} ${value}",
          require => File['/usr/local/sbin/grain-ensure'],
        }
    }
    'singlevalue': {
        exec { "/usr/local/sbin/grain-ensure set ${grain} ${value}":
          unless  => "/usr/local/sbin/grain-ensure contains ${grain} ${value}",
          require => File['/usr/local/sbin/grain-ensure'],
        }
    }
  }
}
