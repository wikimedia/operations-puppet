# manifests/role/subversion.pp

class role::subversion {

    system::role { 'role::subversion': description => 'public, read-only SVN server' }

    class { '::subversion': }

}

