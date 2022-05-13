# SPDX-License-Identifier: Apache-2.0
type Cfssl::Signer_config = Variant[
    Cfssl::Signer_config::Client,
    Cfssl::Signer_config::Local,
    Stdlib::HTTPUrl,
]
