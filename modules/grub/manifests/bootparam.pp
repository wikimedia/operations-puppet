# == Define: grub::bootparam
#
# Sets up grub to pass the specified boot parameter to Linux.
# and/or userland.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the parameter will be provisioned, otherwise it will be
#   removed. The default is 'present'.
#
# [*mode*]
#   Default is 'keyvalue', meaning the parameter being set uses a key=value
#   syntax on the commandline.  Setting this to any other value operates in
#   non-keyvalue mode, which means there's just a keyword but no "=value"
#   portion for this particular option.
#
# [*key*]
#   The parameter name to pass. Defaults to $title.
#
# [*value*]
#   The parameter value to pass. Required if ensure=>present and
#   mode='keyvalue', not allowed when mode != 'keyvalue'.
#
# [*glob*]
#   Whether to replace or remove any value assigned to the specified $key in
#   'keyvalue' mode.  Defaults to true.  Has no effect in non-keyvalue mode.
#
# === Examples
#
#  grub::bootparam { 'quiet':
#      ensure => present,
#  }
#
#  grub::bootparam { 'i/o scheduler':
#      key    => 'elevator',
#      value  => 'deadline',
#  }
#

define grub::bootparam(
  $ensure=present,
  $mode='keyvalue',
  $key=$title,
  $value=undef,
  $glob=true,
) {
    include ::grub

    # Logical sanity contraints:
    if $mode == 'keyvalue' {
        if $ensure == 'present' and $value == undef {
            fail('Cannot set an undefined value in keyvalue mode')
        }
    }
    elsif $value != undef {
        fail('Cannot set a value in non-keyvalue mode')
    }

    $param = $value ? {
        undef   => $key,
        default => "${key}=${value}",
    }

    if $mode != 'keyvalue' or !$glob {
        $change = $ensure ? {
            'present' => "set GRUB_CMDLINE_LINUX/value[. = \"${param}\"] ${param}",
            'absent'  => "rm GRUB_CMDLINE_LINUX/value[. = \"${param}\"]",
        }
    } else {
        $change = $ensure ? {
            'present' => "set GRUB_CMDLINE_LINUX/value[. =~ glob(\"${key}=*\")] ${param}",
            'absent'  => "rm GRUB_CMDLINE_LINUX/value[. =~ glob(\"${key}=*\")]",
        }
    }

    augeas { "grub2 ${param}":
        incl    => '/etc/default/grub',
        lens    => 'Shellvars_list.lns',
        changes => [
            $change,
        ],
        notify  => Exec['update-grub'],
    }
}
