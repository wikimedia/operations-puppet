# gridengine.pp


class gridengine::submit_host($gridmaster = $grid_master) {
	class { 'gridengine':
		gridmaster => $gridmaster,
	}

        package { "gridengine-client":
                ensure => latest,
        }

# Not actually possible in the labs
#	@@sshkey { $fqdn:
#		ensure => present,
#		type => 'ssh-dss',
#		key => $sshdsakey,
#		tag => "sshkey-$grid_master",
#	}
}

