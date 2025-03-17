# SPDX-License-Identifier: Apache-2.0
# The preseed "name" syntax needs to match a BASH "case" syntax
type Install_server::Preseed_host::Name = Pattern[/^(?:[a-z0-9]|\[|\]|\*|\||\-)+$/]
