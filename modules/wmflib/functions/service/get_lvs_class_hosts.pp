# SPDX-License-Identifier: Apache-2.0
# Return a hash of LVS host classes and their corresponding host names.
# A sample output looks like {"high-traffic1"=>["lvs1017"], "high-traffic2"=>["lvs1018"]}...
function wmflib::service::get_lvs_class_hosts() >> Hash {
  include profile::lvs::configuration

  $profile::lvs::configuration::lvs_classes.group_by |$lvs_host, $lvs_class| { $lvs_class }.reduce({}) |$memo, $lvs_data| {
    $memo + {$lvs_data[0] => $lvs_data[1].flatten.sort.filter |$host| {$host =~ /^lvs/}}
  }
}
