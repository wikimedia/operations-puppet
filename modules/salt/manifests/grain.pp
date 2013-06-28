define salt::grain(
  $grain,
  $value) {

  if ! defined(Exec["grain_$grain_$value"]) {
    exec { "grain_$grain_$value":
      command => "/usr/local/sbin/grain-merge $grain $value",
      require => File["/usr/local/sbin/grain-merge"];
    }
  }

}
