class role::labs_vmbuilder {
    class { '::labs_vmbuilder':
        vmbuilder_version => '3';
    }
}
