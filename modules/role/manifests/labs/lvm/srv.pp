# == Class role::labs::lvm::srv
#
# Allocate all of the instance's extra space as /srv
#
# Instead of applying this role, one should consider adding in a role:
#
#     require ::profile::labs::lvm::srv
#
class role::labs::lvm::srv {
    include ::profile::labs::lvm::srv
}
