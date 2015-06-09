include stdlib

define apt::multipackage (
  $overrides={},
  $ensure=latest,
) {
  $distro = $::lsbdistcodename
  if has_key($overrides, $distro) {
    if $overrides[$distro] {
      package{$overrides[$distro]:
        ensure => $ensure,
      }
    }
  } else {
    package{$name:
      ensure => $ensure,
    }
  }    
}

