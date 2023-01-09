# SPDX-License-Identifier: Apache-2.0
# @summary type to validate Linux user ID numbers for system users
# that have been reserved to be consistent across multiple servers
type Admin::UID::System::Global = Integer[900,999]
