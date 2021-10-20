class role::puppet_compiler {

    system::role { 'puppet_compiler': description => 'Puppet compiler jenkins slave'}

    include ::profile::puppet_compiler

}
