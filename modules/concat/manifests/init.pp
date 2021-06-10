# @summary
#   Manages a file, compiled from one or more text fragments.
#
# @example
#   concat { '/tmp/concat':
#     ensure => present,
#     owner  => 'root',
#     group  => 'root',
#     mode   => '0644',
#   }
#
# @param backup
#   Specifies whether (and how) to back up the destination file before overwriting it. Your value gets passed on to Puppet's native file
#   resource for execution. Valid options: true, false, or a string representing either a target filebucket or a filename extension
#   beginning with ".".
#
# @param ensure
#   Specifies whether the destination file should exist. Setting to 'absent' tells Puppet to delete the destination file if it exists, and
#   negates the effect of any other parameters.
#
# @param ensure_newline
#   Specifies whether to add a line break at the end of each fragment that doesn't already end in one.
#
# @param format
#   Specify what data type to merge the fragments as. Valid options: 'plain', 'yaml', 'json', 'json-array', 'json-pretty',
#   'json-array-pretty'.
#
# @param force
#   Specifies whether to merge data structures, keeping the values with higher order. Used when format is specified as a value other than
#   'plain'.
#
# @param group
#   Specifies a permissions group for the destination file. Valid options: a string containing a group name or integer containing a gid.
#
# @param mode
#   Specifies the permissions mode of the destination file. Valid options: a string containing a permission mode value in octal notation.
#
# @param order
#   Specifies a method for sorting your fragments by name within the destination file. You can override this setting for individual
#   fragments by adjusting the order parameter in their concat::fragment declarations.
#
# @param owner
#   Specifies the owner of the destination file. Valid options: a string containing a username or integer containing a uid.
#
# @param path
#   Specifies a destination file for the combined fragments.
#
# @param replace
#   Specifies whether to overwrite the destination file if it already exists.
#
# @param selinux_ignore_defaults
#   See the file type's selinux_ignore_defaults documentention:
#   https://docs.puppetlabs.com/references/latest/type.html#file-attribute-selinux_ignore_defaults
#
# @param selrange
#   See the file type's selrange documentention: https://docs.puppetlabs.com/references/latest/type.html#file-attribute-selrange
#
# @param selrole
#   See the file type's selrole documentention: https://docs.puppetlabs.com/references/latest/type.html#file-attribute-selrole
#
# @param seltype
#   See the file type's seltype documentention: https://docs.puppetlabs.com/references/latest/type.html#file-attribute-seltype
#
# @param seluser
#   See the file type's seluser documentention: https://docs.puppetlabs.com/references/latest/type.html#file-attribute-seluser
#
# @param show_diff
#   Specifies whether to set the show_diff parameter for the file resource. Useful for hiding secrets stored in hiera from insecure
#   reporting methods.
#
# @param validate_cmd
#   Specifies a validation command to apply to the destination file.
#
# @param warn
#   Specifies whether to add a header message at the top of the destination file. Valid options: the booleans true and false, or a string
#   to serve as the header.
#   If you set 'warn' to true, concat adds the following line with an order of 0:
#   `# This file is managed by Puppet. DO NOT EDIT.`
#   Before 2.0.0, this parameter would add a newline at the end of the warn message. To improve flexibilty, this was removed. Please add
#   it explicitly if you need it.
#
define concat (
  Enum['present', 'absent']          $ensure                  = 'present',
  Stdlib::Absolutepath               $path                    = $name,
  Optional[Variant[String, Integer]] $owner                   = undef,
  Optional[Variant[String, Integer]] $group                   = undef,
  String                             $mode                    = '0644',
  Variant[Boolean, String]           $warn                    = false,
  Boolean                            $show_diff               = true,
  Variant[Boolean, String]           $backup                  = 'puppet',
  Boolean                            $replace                 = true,
  Enum['alpha','numeric']            $order                   = 'alpha',
  Boolean                            $ensure_newline          = false,
  Optional[String]                   $validate_cmd            = undef,
  Optional[Boolean]                  $selinux_ignore_defaults = undef,
  Optional[String]                   $selrange                = undef,
  Optional[String]                   $selrole                 = undef,
  Optional[String]                   $seltype                 = undef,
  Optional[String]                   $seluser                 = undef,
  Optional[String]                   $format                  = 'plain',
  Optional[Boolean]                  $force                   = false,
) {
  $safe_name            = regsubst($name, '[\\\\/:~\n\s\+\*\(\)@]', '_', 'G')
  $default_warn_message = "# This file is managed by Puppet. DO NOT EDIT.\n"

  case $warn {
    true: {
      $warn_message = $default_warn_message
      $_append_header = true
    }
    false: {
      $warn_message = ''
      $_append_header = false
    }
    default: {
      $warn_message = $warn
      $_append_header = true
    }
  }

  if $ensure == 'present' {
    concat_file { $name:
      tag                     => $safe_name,
      path                    => $path,
      owner                   => $owner,
      group                   => $group,
      mode                    => $mode,
      selinux_ignore_defaults => $selinux_ignore_defaults,
      selrange                => $selrange,
      selrole                 => $selrole,
      seltype                 => $seltype,
      seluser                 => $seluser,
      replace                 => $replace,
      backup                  => $backup,
      show_diff               => $show_diff,
      order                   => $order,
      ensure_newline          => $ensure_newline,
      validate_cmd            => $validate_cmd,
      format                  => $format,
      force                   => $force,
    }

    if $_append_header {
      concat_fragment { "${name}_header":
        target  => $name,
        tag     => $safe_name,
        content => $warn_message,
        order   => '0',
      }
    }
  } else {
    concat_file { $name:
      ensure => $ensure,
      tag    => $safe_name,
      path   => $path,
      backup => $backup,
    }
  }
}
