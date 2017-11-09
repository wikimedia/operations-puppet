# Class: profile::birdlg::lg_backend
#
# This profile installs all the bird-lg backend related parts as WMF requires it
#
# === Actions
#       Install bird with the looking glass confiuration (v4 only)
#       Deploys bird-lg (with uwsgi)
#       Configure firewall rules
#
# === Parameters
#
# [*neighbors_list*]
#   List of BGP neighbors to peer with
#
# [*access_list*]
#   BirdLG frontend allowed to connect to this backend
#
# [*port*]
#   Port for BirdLG backend to listen for inbound frontend requests
#
# === Sample Usage:
#       include profile::birdlg::lg_backend


class profile::birdlg::lg_backend(
  $neighbors_list = hiera('profile::birdlg::neighbors_list'),
  $access_list = hiera('profile::birdlg::access_list', ['127.0.0.1']),
  $port = hiera('profile::birdlg::port', 5000)
) {

  $neighbors_for_ferm = join($neighbors_list, ' ')

  ferm::service { 'bird-bgp':
      proto  => 'tcp',
      port   => '179',
      srange => "(${neighbors_for_ferm})",
      before => Class['::bird'],
  }

  ferm::service { 'bird-lg-proxy':
      proto  => 'tcp',
      port   => $port,
      srange => '$PRODUCTION_NETWORKS',
      before => Class['::bird'],
  }

  class { '::bird':
        config_template => 'bird/bird_lookingglass.conf.erb', # TODO create template
        neighbors       => $neighbors_list,
    }

class { 'birdlg::lg_backend':
      port        => $port,
      access_list => $access_list,
      require     => Class['::bird'],
  }

}
