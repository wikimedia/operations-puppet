include stdlib

define apt::pypackage_parser (
  $package,
  $config = true,
  $prefix='python'
) {
  $distro = $::lsbdistcodename
  if is_bool($config) {
    if $config {
      $pypackage = $package
    } else {
      $pypackage = undef
    }
  } elsif is_string($config) {
    $pypackage = $config
  } else {
    if has_key($config, $distro) {
      $val = $config[$distro]
      if is_bool($val) {
        if $val {
          $pypackage = $package
        } else {
          $pypackage = undef
        }
      } else {
        $pypackage = $val
      }
    } else {
      $pypackage = undef
    }
  }

  if $pypackage != undef {
    package{"${prefix}-${pypackage}": ensure => latest}
  }
}

define apt::pypackage (
  $py2=true,
  $py3=false
) {
  apt::pypackage_parser {"${name}-py2": package => $name, config => $py2, prefix => 'python' }
  apt::pypackage_parser {"${name}-py3": package => $name, config => $py3, prefix => 'python3' }
  
}

