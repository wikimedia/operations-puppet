# http://www.librenms.org/ | https://github.com/librenms/librenms
class role::librenms {
    system::role { 'librenms': description => 'LibreNMS' }

    include ::network::constants
    include ::passwords::librenms
    include ::passwords::network
    include ::profile::librenms
}
