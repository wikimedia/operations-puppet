# SPDX-License-Identifier: Apache-2.0
# @summary type to validate Linux user ID numbers
type Admin::UID = Variant[Admin::UID::User, Admin::UID::System]
