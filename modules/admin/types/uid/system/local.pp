# SPDX-License-Identifier: Apache-2.0
# @summary type to validate Linux user ID numbers for system users
# that are local to a system
type Admin::UID::System::Local = Integer[100,499]
