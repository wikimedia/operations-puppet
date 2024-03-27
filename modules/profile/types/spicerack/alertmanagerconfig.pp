# SPDX-License-Identifier: Apache-2.0
# @summary Spicerack configuration for contacting Alertmanager instances
type Profile::Spicerack::AlertmanagerConfig = Struct[{
  instances        => Hash[
    String[1],
    Struct[{
      urls => Array[Stdlib::HTTPUrl, 1],
    }],
  ],
  default_instance => String[1],
}]
