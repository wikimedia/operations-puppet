# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Rpki = Struct[{
    vrpProvider                 => Enum['ntt', 'cloudflare', 'rpkiclient', 'ripe', 'external', 'api'],
    preCacheROAs                => Optional[Boolean],
    refreshVrpListMinutes       => Optional[Integer[5]],
    vrpFile                     => Optional[String[1]],
    markDataAsStaleAfterMinutes => Optional[Integer[0]],
}]
