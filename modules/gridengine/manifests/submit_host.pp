# gridengine.pp


class gridengine::submit_host($gridmaster = $grid_master) {
	class { 'gridengine':
		gridmaster => $gridmaster,
	}

        package { "gridengine-client":
                ensure => latest,
        }

        cron { "pull-accounting-from-shared":
          ensure => absent,
        }

        file { "/var/lib/gridengine/default/common/accounting":
          ensure => link,
          target => "/data/project/.system/accounting",
        }

# Not actually possible in the labs
#	@@sshkey { $fqdn:
#		ensure => present,
#		type => 'ssh-dss',
#		key => $sshdsakey,
#		tag => "sshkey-$grid_master",
#	}
}

