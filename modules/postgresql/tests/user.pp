#

include ::postgresql::server
postgresql::user { 'testuser':
  ensure   => 'present',
  user     => 'testuser',
  password => 'pass',
  cidr     => '127.0.0.1/32',
  type     => 'host',
  method   => 'trust',
  database => 'template1',
}
