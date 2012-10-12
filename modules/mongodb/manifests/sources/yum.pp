class mongodb::sources::yum inherits mongodb::params {
  yumrepo { '10gen':
    baseurl   => $mongodb::params::baseurl,
    gpgcheck  => '0',
    enabled   => '1',
  }
}
