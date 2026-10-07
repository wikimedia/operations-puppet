# SPDX-License-Identifier: Apache-2.0
# The name of a Puppet role, as in role(), for example 'ceph::admin'.
type Wmflib::Role = Pattern[/\A\w+(::\w+)*\z/]
