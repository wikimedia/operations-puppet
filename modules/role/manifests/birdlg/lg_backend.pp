# Class: role::birdlg::lg_backend
#
# This profile installs all the bird-lg backend related parts as WMF requires it
#
# Actions:
#       Deploy bird-lg backend
#
# Requires:
#
# Sample Usage:
#       include role::birdlg::lg_backend
#

class role::birdlg::lg_backend {

  system::role { 'birdlg::lg_backend': description => 'Bird-lg backend' }

  include ::profile::birdlg::lg_backend

}
