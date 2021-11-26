class role::puppet_compiler {

    system::role { 'puppet_compiler': description => 'Puppet compiler jenkins slave'}

    include profile::ci::slave::labs::common
    include profile::puppet_compiler
    include profile::puppet_compiler::puppetdb
    include profile::puppet_compiler::clean_reports
}
