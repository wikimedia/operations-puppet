# Class: pmacct
#
# This installs and mangages pmacct configuraiton
# http://www.pmacct.net/
#
# Will initially be added to node 'netmon1001'

class pmacct {

    # Install package and make sure user and directories are set
    class {'pmacct::install':
        home => '/srv/pmacct',
    }

    # Iterate over the device list to create new configs
    # FIXME: Review daniel's different method for iterating over a hash..
    create_resources('pmacct::configs', $pmacct::configuration::agents)

    # Iterate over the device list to verify/check iptables redirects
    # FIXME: ferm (should probably happen in one iterate...

    service {'pmacctd':
        ensure => running;
    }
}
