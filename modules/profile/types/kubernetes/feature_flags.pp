# SPDX-License-Identifier: Apache-2.0
# General feature flag key to facilitate easier testing of experimental features,
# as well as to indicate that a specific feature is in an experimental state.
#
# The Puppet type can be modified or adapted to accommodate the needs of a given feature.
type Profile::Kubernetes::Feature_flags = Hash[String, Boolean]
