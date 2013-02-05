class jenkins::group {

  class jenkins {
    group { "jenkins":
      name      => "jenkins",
      ensure    => present,
      allowdupe => false;
    }
  }

}
