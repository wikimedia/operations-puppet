# Class: role::birdlg::lg_frontend
#
# This profile installs all the bird-lg frontend related parts as WMF requires it
#
# Actions:
#       Deploy bird-lg frontend
#
# Requires:
#
# Sample Usage:
#       include role::birdlg::lg_frontend
#

class role::birdlg::lg_frontend {

  system::role { 'birdlg::lg_frontend': description => 'Bird-lg frontend' }

  include ::profile::birdlg::lg_frontend

}
