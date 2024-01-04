# SPDX-License-Identifier: Apache-2.0

# @type Prometheus::Blackbox::Check::Instance

# Describe which Prometheus instances can import checks
# i.e. they will call 'prometheus::blackbox::import_checks'
type Prometheus::Blackbox::Check::Instance = Enum['ops', 'tools']
