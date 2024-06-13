# SPDX-License-Identifier: Apache-2.0
# @summary Server to host terraform.wmcloud.org/registry
class role::wmcs::terraform::registry () {
  include profile::labs::cindermount::srv
  include profile::terraform::registry
}
