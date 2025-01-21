# SPDX-License-Identifier: Apache-2.0
# acme-chief account configuration
# [*regr*]
#  ACME registration object as expected by acme-chief
#  i.e.:  '{"body": {}, "uri": "https://acme-staging-v02.api.letsencrypt.org/acme/acct/7090084"}'
# [*directory*]
#  ACME directory URL
#  i.e.: https://acme-staging-v02.api.letsencrypt.org/directory"
# [*default*]
#  Optional parameter that flags an account as the default one
#  (it will be used when certificates don't have an account specified on their configuration)

type Acme_chief::Account = Struct[{
        'regr'      => String,
        'directory' => Stdlib::HTTPSUrl,
        'default'   => Optional[Boolean],
}]
