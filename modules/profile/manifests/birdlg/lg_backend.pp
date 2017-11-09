# Class: profile::birdlg::lg_backend
#
# This profile installs all the bird-lg backend related parts as WMF requires it
#
# Actions:
#       Deploy bird-lg
#       Install uwsgi
#       Configure firewall rules
#
# Requires:
#
# Sample Usage:
#       include profile::birdlg::lg_backend


class profile::birdlg::lg_backend(
) {
  $port = 5000

  include passwords::bird-lg
  $secret_key = $passwords::birdlg::secret_key   ### TODO Not defined yet


  ferm::service { 'bird-lg-proxy':
      proto  => 'tcp',
      port   => $port,
      srange => '$PRODUCTION_NETWORKS',
  }

class { 'birdlg::lg_backend':
      port        => $port,
      access_list => ['208.80.154.5','208.80.153.110'],
  }

}
