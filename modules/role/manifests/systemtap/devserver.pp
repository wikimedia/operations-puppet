# == Class: role::systemtap::devserver
#
# Role to configure a SystemTap development server
#
class role::systemtap::devserver {
    include ::systemtap::devserver

    system::role { 'role::systemtap::devserver':
        description => 'SystemTap development environment',
    }
}
