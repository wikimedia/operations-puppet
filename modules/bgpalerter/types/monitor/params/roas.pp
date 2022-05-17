# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Monitor::Params::Roas = Struct[{
    enableDiffAlerts        => Optional[Boolean],
    enableExpirationAlerts  => Optional[Boolean],
    enableExpirationCheckTA => Optional[Boolean],
    enableDeletedCheckTA    => Optional[Boolean],
    roaExpirationAlertHours => Optional[Integer[1]],
    checkOnlyASns           => Optional[Boolean],
    toleranceExpiredRoasTA  => Optional[Integer[1]],
    toleranceDeletedRoasTA  => Optional[Integer[1]],
}]
