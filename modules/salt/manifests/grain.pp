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
# [*replace*]
#   If true, replaces the value in the grain. If false, it adds the value.
#   Defaults to true.
#
# === Examples
#
#  salt::grain { 'deployment_target':
#    value => 'parsoid',
#  }
#
#  salt::grain { 'cluster':
#    value => 'eqiad_text_cache',
#    replace => true,
#  }
#
define salt::grain(
        $value,
        $grain  = $title,
        $ensure = present,
        $replace = false,
){
    validate_ensure($ensure)

    $command = $replace ? {
        true    => 'set',
        default => 'add',
    }
    case $ensure {
        'absent': {
            exec { "/usr/local/sbin/grain-ensure remove ${grain} ${value}":
                onlyif  => "/usr/local/sbin/grain-ensure contains ${grain} ${value}",
                require => File['/usr/local/sbin/grain-ensure'],
            }
        }
        'present': {
            exec { "/usr/local/sbin/grain-ensure ${command} ${grain} ${value}":
                unless  => "/usr/local/sbin/grain-ensure contains ${grain} ${value}",
                require => File['/usr/local/sbin/grain-ensure'],
            }
        }
    }
}
