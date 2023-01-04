# SPDX-License-Identifier: Apache-2.0
# @summary type to validate Linux user ID numbers for regular users
type Admin::UID::User = Integer[1000,59999]
