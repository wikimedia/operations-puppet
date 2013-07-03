define salt::grain(
  $grain,
  $value,
  $ensure = present,
) {

  $opts = $ensure ? {
    absent  => '--purge',
    default => '',
  }

  if ! defined(Exec["grain_$grain_$value"]) {
    exec { "grain_$grain_$value":
      command => "/usr/local/sbin/grain-merge $opts $grain $value",
      require => File["/usr/local/sbin/grain-merge"];
    }
  }

}
