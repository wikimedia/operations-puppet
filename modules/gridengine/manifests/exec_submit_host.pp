# gridengine/exec_host.pp

## Stupid [mumble] [mumble] puppet

class gridengine::exec_submit_host($gridmaster = $grid_master) {
    class { 'gridengine':
        gridmaster => $gridmaster,
    }

    package { 'gridengine-exec':
        ensure => latest,
    }

    package { [ 'gridengine-client', 'jobutils' ]:
        ensure => latest,
    }

    file { '/var/lib/gridengine/default/common/accounting':
        ensure => link,
        target => '/data/project/.system/accounting',
    }

# Not actually possible in the labs
#   @@sshkey { $fqdn:
#       ensure => present,
#       type => 'ssh-dss',
#       key => $sshdsakey,
#       tag => "sshkey-$grid_master",
#   }

}

