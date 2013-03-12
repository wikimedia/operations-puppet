class jenkins::group {

  group { "jenkins":
    name      => "jenkins",
    ensure    => present,
    system    => true,
    allowdupe => false,
  }

}
