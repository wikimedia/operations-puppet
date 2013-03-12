class jenkins::group {
  group { 'jenkins':
    ensure    => present,
    name      => 'jenkins',
    system    => true,
    allowdupe => false,
  }
}
