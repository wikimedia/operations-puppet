# gridengine.pp


class gridengine::submit_host($gridmaster = $grid_master) {
	class { 'gridengine':
		gridmaster => $gridmaster,
	}

        package { [ "gridengine-client", "jobutils" ]:
                ensure => latest,
        }

        cron { "pull-accounting-from-shared":
          command => "cp -f /data/project/.system/accounting /var/lib/gridengine/default/common/accounting.tmp && mv -f /var/lib/gridengine/default/common/accounting.tmp /var/lib/gridengine/default/common/accounting",
          user => root,
          minute => [1, 6, 11, 16, 21, 26, 31, 36, 41, 46, 51, 56],
          ensure => present;
        }

        # Temporary hack to manage obsolete files in /usr/local/bin.
        # TODO: Remove when no longer needed.
        file { [ "/usr/local/bin/job", "/usr/local/bin/jstart",
                 "/usr/local/bin/jstop", "/usr/local/bin/jsub"]:
          ensure => link,
          target => regsubst(name, "^/usr/local/bin/", "/usr/bin/")
        }

# Not actually possible in the labs
#	@@sshkey { $fqdn:
#		ensure => present,
#		type => 'ssh-dss',
#		key => $sshdsakey,
#		tag => "sshkey-$grid_master",
#	}
}

