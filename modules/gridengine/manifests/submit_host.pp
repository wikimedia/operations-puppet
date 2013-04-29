# gridengine.pp


class gridengine::submit_host($gridmaster = $grid_master) {
	require gridengine($gridmaster)

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

