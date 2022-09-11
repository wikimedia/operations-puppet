# SPDX-License-Identifier: Apache-2.0
# @summary Server to host terraform.wmcloud.org/registry
class role::wmcs::terraform::registry () {
  system::role { 'wmcs::terraform::registry':
    description => 'Terraform module registry',
  }

  include ::profile::terraform::registry
}
