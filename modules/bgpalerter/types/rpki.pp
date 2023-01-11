# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Rpki = Struct[{
    vrpProvider                             => Enum['ntt', 'cloudflare', 'rpkiclient', 'ripe', 'external', 'api'],
    Optional['preCacheROAs']                => Boolean,
    Optional['refreshVrpListMinutes']       => Integer[5],
    Optional['vrpFile']                     => String[1],
    Optional['markDataAsStaleAfterMinutes'] => Integer[0],
    Optional['url']                         => Stdlib::HTTPUrl,
}]
