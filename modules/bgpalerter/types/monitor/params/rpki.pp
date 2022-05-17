# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Monitor::Params::Rpki = Struct[{
    checkUncovered            => Boolean,
    checkDisappearing         => Boolean,
    thresholdMinPeers         => Integer[1],
    maxDataSamples            => Optional[Integer[1]],
    cacheValidPrefixesSeconds => Optional[Integer[60]],
}]
