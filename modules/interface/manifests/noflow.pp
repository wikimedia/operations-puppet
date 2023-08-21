# SPDX-License-Identifier: Apache-2.0
# Definition: interface::noflow
#
# Disable ethernet flow control at boot time via up-commands, and also add a
# parameter to set an optional pre-up command in addition to the current
# up/post-up one.
#
# Parameters:
# - $interface=$name:
#   The network interface to operate on
# - $use_noflow_iface_preup:boolean
#   The command to run on pre-up
define interface::noflow($interface=$name,$use_noflow_iface_preup=false) {
    # Command will fail on some hosts, depending on kernel/driver revs and/or
    # ethernet hardware capabilities, in which case we don't care, hence ||:
    $cmd = "ethtool -A ${interface} autoneg off tx off rx off ||:"

    # we only want to run a pre-up command.
    if $use_noflow_iface_preup {
      interface::pre_up_command { "noflow-${interface}":
          interface => $interface,
          command   => $cmd,
          require   => Package['ethtool'],
      }
    } else {
      # Add to ifup commands in /etc/network/interfaces
      interface::up_command { "noflow-${interface}":
          interface => $interface,
          command   => $cmd,
          require   => Package['ethtool'],
      }
    }

}
