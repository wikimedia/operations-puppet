# = Define: kmod::setting
#
# == Example
#
#
define kmod::setting(
  $file,
  $category,
  $option = undef,
  $value = undef,
  $module = $name,
  $ensure = 'present',
) {

  include ::kmod

  ensure_resource('file', $file, { 'ensure' => 'file'} )
  case $ensure {
    'present': {
      if $option {
        $changes = [
          "set ${category}[. = '${module}'] ${module}",
          "set ${category}[. = '${module}']/${option} ${value}",
        ]
      } else {
        $changes = [
          "set ${category}[. = '${module}'] ${module}",
        ]
      }
    }

    'absent': {
      $changes = "rm ${category}[. = '${module}']"
    }

    default: { fail ( "unknown ensure value ${ensure}" ) }
  }

  augeas { "kmod::setting ${title} ${module}":
    incl    => $file,
    lens    => 'Modprobe.lns',
    changes => $changes,
    require => File[$file],
  }
}
