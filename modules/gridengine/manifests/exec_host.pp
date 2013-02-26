# gridengine/exec_host.pp

class gridengine::exec_host {
	require gridengine

        package { "gridengine-exec":
                ensure => latest,
        }

# Not actually possible in the labs
#	Sshkey <<| tag == "sshkey-$grid_master" |>>
}

