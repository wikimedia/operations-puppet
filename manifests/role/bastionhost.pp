# bastion host roles
class role::bastionhost::general {
    system::role { 'bastionhost::general':
        description => 'Bastion host for all shell users',
    }

    include ::bastionhost
    include base::firewall
    include role::backup::host

    $admin_module_path = get_module_path('admin')
    $admin_data = loadyaml("${admin_module_path}/data/data.yaml")
    class { 'admin': groups => keys($admin_data['groups']) }

    backup::set {'home': }

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

}

class role::bastionhost::opsonly {
    system::role { 'bastionhost::opsonly':
        description => 'Bastion host restricted to the ops team',
    }

    include ::bastionhost
    include base::firewall
    include role::backup::host

    backup::set {'home': }

    ferm::service { 'ssh':
        desc  => 'SSH open from everywhere, this is a bastion host',
        prio  => '01',
        proto => 'tcp',
        port  => 'ssh',
    }

}
