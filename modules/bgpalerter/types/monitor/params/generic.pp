# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Monitor::Params::Generic = Struct[{
    thresholdMinPeers => Integer[1],
    maxDataSamples    => Optional[Integer[1]],
}]
