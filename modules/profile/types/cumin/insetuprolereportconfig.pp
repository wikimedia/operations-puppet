# SPDX-License-Identifier: Apache-2.0
# @summary Owners and roles mapping for the insetup role report
type Profile::Cumin::InsetupRoleReportConfig = Struct[{
  audit_owner  => Wmflib::Email,
  debug_owners => Array[Wmflib::Email],
  mapping      => Hash[Wmflib::Email, Array[String[1], 1]],
}]
