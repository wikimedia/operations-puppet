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
# [*key*]
#   The parameter name to pass. Defaults to $title.
#
# [*value*]
#   The parameter value to pass. Optional.
#
# [*glob*]
#   Whether to replace or remove any value assigned to the specified $key.
#   Defaults to true.
#
# === Examples
#
#  grub::bootparam { 'quiet':
#      ensure => present,
#  }
#
#  grub::bootparam { 'i/o scheduler':
#      ensure   => present,
#      elevator => 'elevator',
#      value    => 'deadline',
#  }
#

class grub::bootparam(
  $ensure=present,
  $key=$title,
  $value=undef,
  $glob=true,
) {
    include grub

    if versioncmp($::augeasversion, '1.2.0') < 0 {
        fail("not supported on systems running an old augeas")
    }

    $param = $value ? {
        undef   => $key,
        default => "${key}=${value}",
    }

    if $glob {
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

    augeas { 'grub2':
        incl    => '/etc/default/grub',
        lens    => 'Shellvars_list.lns',
        changes => [
            $change,
        ],
        notify  => Exec['update-grub'],
    }
}
