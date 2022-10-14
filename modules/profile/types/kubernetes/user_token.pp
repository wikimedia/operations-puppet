# SPDX-License-Identifier: Apache-2.0
type Profile::Kubernetes::User_token = Struct[{
    'token'        => String,
    'groups'       => Optional[Array[String]],
    'constrain_to' => Optional[String]
}]
