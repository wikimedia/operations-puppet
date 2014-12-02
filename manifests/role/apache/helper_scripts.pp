# role for a host with apache helper scripts
class role::apache::helper_scripts {

    system::role { 'apache::helper_scripts':
        description => 'server has apache helper scripts',
    }

    include ::apache::helper_scripts

}
