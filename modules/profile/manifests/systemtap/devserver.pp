# SPDX-License-Identifier: Apache-2.0
# == Class: profile::systemtap::devserver
#
# configure a SystemTap development server
#
class profile::systemtap::devserver {

    class {'systemtap::devserver': }
}
