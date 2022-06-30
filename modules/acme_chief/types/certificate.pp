# SPDX-License-Identifier: Apache-2.0
type Acme_chief::Certificate = Struct[{
    'CN'                 => Wmflib::Host::Wildcard,
    'SNI'                => Array[Wmflib::Host::Wildcard],
    'challenge'          => String[1],
    'authorized_regexes' => Optional[Array[String[1]]],
    'authorized_hosts'   => Optional[Array[Stdlib::Host]],
    'staging_time'       => Optional[Integer[1]],
    'prevalidate'        => Optional[Boolean],
    'skip_invalid_snis'  => Optional[Boolean],
}]
