# gridengine.pp


class gridengine::shadow_master($gridmaster = $grid_master) {
	class { 'gridengine':
		gridmaster => $gridmaster,
	}

        package { "gridengine-master":
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
