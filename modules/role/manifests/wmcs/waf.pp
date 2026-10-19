# SPDX-License-Identifier: Apache-2.0
# @summary Web Application Firewall management tools
class role::wmcs::waf () {
  include profile::conftool::client
  include profile::conftool::conftool2git
  include profile::wmcs::waf::hiddenparma
}
