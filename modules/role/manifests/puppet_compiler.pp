# filtertags: labs-project-toolsbeta labs-project-puppet3-diffs
class role::puppet_compiler {

    system::role { 'puppet_compiler': description => 'Puppet compiler jenkins slave'}

    include ::profile::puppet_compiler

}
