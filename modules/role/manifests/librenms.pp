# http://www.librenms.org/ | https://github.com/librenms/librenms
class role::librenms {
    system::role { 'librenms': description => 'LibreNMS' }

    include ::profile::librenms
}
