class role::puppet_compiler::puppetdb {
    # Users of this role will need to add a volume for srv
    # https://wikitech.wikimedia.org/wiki/Help:Adding_Disk_Space_to_Cloud_VPS_instances
    include profile::ci::slave::labs::common
    include profile::puppet_compiler::puppetdb
}
