# SPDX-License-Identifier: Apache-2.0
# See https://gitlab.wikimedia.org/repos/sre/vopsbot/-/blob/main/user.go
type Vopsbot::User = Struct[{
  'vo_name' => String,
  'team'    => Optional[String],
  'vo_admin' => Optional[Boolean],
}]
