# SPDX-License-Identifier: Apache-2.0
type Wmflib::DNS::Srv = Pattern[/\A_[a-zA-Z][a-zA-Z0-9\-]+\._(tcp|udp|dccp|sctp)\.(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\z/]
