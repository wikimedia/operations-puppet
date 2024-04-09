# SPDX-License-Identifier: Apache-2.0
# @summary Spicerack configuration for contacting Alertmanager instances
type Profile::Spicerack::AlertmanagerConfig = Struct[{
  instances        => Hash[
    String[1],
    Struct[{
      urls           => Array[Stdlib::HTTPUrl, 1],
      http_use_proxy => Optional[Boolean],
      http_username  => Optional[String[1]],
      http_password  => Optional[String[1]],
    }],
  ],
  default_instance => String[1],
}]
