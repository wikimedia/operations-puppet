<!-- SPDX-License-Identifier: Apache-2.0 -->
# SystemTap Puppet Module #

A Puppet module for configuring SystemTap development servers.

# Usage #

To configure a development environment where SystemTap probes can be compiled,
include systemtap::devserver. The following sample probe can be executed on the
development server to check if the basic SystemTap functionalities are working
fine: `stap -e 'probe oneshot { println("hello world") }'`.


# See also #
https://wikitech.wikimedia.org/wiki/SystemTap
