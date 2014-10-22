# https://noc.wikimedia.org/
class role::noc {

    system::role { 'role::noc': description => 'noc.wikimedia.org' }

    class { '::noc': }
}

