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
#   If 'present', adds value to grain. If 'absent', removes it. Defaults
#   to 'present'.
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
  if $ensure == 'absent' {
    exec { "grain-ensure remove ${grain} ${value}":
      onlyif  => "grain-ensure contains ${grain} ${value}",
      require => File['/usr/local/sbin/grain-ensure'],
    }
  } else {
    exec { "grain-ensure set ${grain} ${value}":
      unless  => "grain-ensure contains ${grain} ${value}",
      require => File['/usr/local/sbin/grain-ensure'],
    }
  }
}
