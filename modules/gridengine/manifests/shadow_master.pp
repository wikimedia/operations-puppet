# gridengine.pp


class gridengine::shadow_master($gridmaster = $grid_master) {
	require gridengine($gridmaster)

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
