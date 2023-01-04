# SPDX-License-Identifier: Apache-2.0
# @summary type to validate phabricator tasks
type Phabricator::Task = Pattern[/T\d{4,8}/]
