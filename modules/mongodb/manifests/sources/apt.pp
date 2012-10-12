class mongodb::sources::apt inherits mongodb::params {
  include apt

  if $mongodb::location {
    $location = $mongodb::location
  } else {
    $location = $mongodb::params::locations[$mongodb::init]
  }

  apt::source { '10gen':
    location    => $location,
    release     => 'dist',
    repos       => '10gen',
    key         => '7F0CEB10',
    key_server  => 'keyserver.ubuntu.com',
    include_src => false,
  }
}
