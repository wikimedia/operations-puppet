# Class: pmacct
#
# This installs and mangages pmacct configuraiton
# http://www.pmacct.net/
#
# Will initially be added to node 'netmon1001'

class pmacct (
        $pmacct_database,
        $pmacct_agents
) {
    # Install package and make sure user and directories are set
    include pmacct::install

    # Iterate over the device list to create new configs
    # FIXME: Review daniel's different method for iterating over a hash..
    create_resources(pmacct::configs, $pmacct_agents)

    service {'pmacctd':
        ensure => running;
    }
}
