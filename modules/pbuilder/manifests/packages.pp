class pbuilder::packages {

  package { [
    'build-essential',
    'cdbs',
    'debhelper',
    'dupload',
    'fakeroot',
    'git-buildpackage',
    'libcrypt-ssleay-perl',
    'libio-socket-ssl-perl',
    'quilt',
  ]: ensure => latest;
  }

}
