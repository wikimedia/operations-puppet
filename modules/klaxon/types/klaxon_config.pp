# SPDX-License-Identifier: Apache-2.0
# == Type: Klaxon::Klaxon_config
#
# Configuration for Klaxon: a mix of secret data and some config knobs.
#
#  [*vo_api_id*]
#    [string] VictorOps-provided API account identifier. required.
#
#  [*vo_api_key*]
#    [string] VictorOps-provided API access key. required.
#
#  [*vo_create_incident_url*]
#    [string] VictorOps-provided URL for the REST Integration incident creation endpoint. required.
#
#  [*secret_key*]
#    [string] Some random secret data used by Flask to secure client-side session data. required.
#
#  [*admin_contact_email*]
#    [string] email contact address for the instance administrator. required.
#
#  [*team_ids_filter*]
#    [string] If provided, a comma-separated list of team IDs for which to display pages.
#             If unset, no filter. optional.

type Klaxon::Klaxon_config = Struct[{
    vo_api_id              => String[1],
    vo_api_key             => String[1],
    vo_create_incident_url => Stdlib::HTTPUrl,
    secret_key             => String[1],
    admin_contact_email    => String[1],
    team_ids_filter        => Optional[String[1]],
    esc_policy_ids_filter  => Optional[String[1]],
}]
