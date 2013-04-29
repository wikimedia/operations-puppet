# gridengine.pp


class gridengine::master {
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
#		tag => "sshkey-$fqdn",
#	}
}
