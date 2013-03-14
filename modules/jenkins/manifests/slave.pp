class jenkins::slave {

  if $::realm == 'production' {
    include jenkins::user
  }
  # On labs, user need to be setup via the labsconsole

  # Slave needs openjdk, it will then happilly fetch all the components
  # it needs from the master over ssh.
  java { 'java-7-openjdk': version => 7 }

}
