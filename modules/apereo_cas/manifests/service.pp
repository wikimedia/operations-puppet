# SPDX-License-Identifier: Apache-2.0
define apereo_cas::service (
  Integer                              $id,
  String                               $service_id,
  Apereo_cas::Service::Class           $service_class   = 'RegexRegisteredService',
  Apereo_cas::Service::Release_policy  $release_policy  = 'ReturnAllAttributeReleasePolicy',
  Apereo_cas::Service::Access_strategy $access_strategy = 'DefaultRegisteredServiceAccessStrategy',
  Boolean                              $require_u2f     = false,
  Array[String]                        $required_groups = [],
  Hash                                 $properties      = {},
) {
  include apereo_cas
  $ldap_root = "${apereo_cas::ldap_group_cn},${apereo_cas::ldap_base_dn}"
  if $required_groups.empty() {
    $_access_strategy = {'@class' => "org.apereo.cas.services.${access_strategy}"}
  } else {
    $ldap_groups = $required_groups.map |$group| { "cn=${group},${ldap_root}" }
    $_access_strategy = {
      '@class'             => "org.apereo.cas.services.${access_strategy}",
      'requiredAttributes' => {
        '@class'   => 'java.util.HashMap',
        'memberOf' => [
          'java.util.HashSet',
          $ldap_groups,
        ]
      }
    }
  }
  # We could make this a bit more flexible with failureMode
  # but for now we will just block set CLOSED
  # https://apereo.github.io/cas/6.1.x/mfa/Configuring-Multifactor-Authentication.html#failure-modes
  $multifactor_policy = $require_u2f ? {
      false   => {},
      default => {
          'multifactorPolicy' => {
              '@class'       => 'org.apereo.cas.services.DefaultRegisteredServiceMultifactorPolicy',
              'failureMode'  => 'CLOSED',
              'multifactorAuthenticationProviders' => [ 'java.util.LinkedHashSet', [ 'mfa-u2f' ]],
          }
      }
  }

  $base_data = {
    '@class'                 => "org.apereo.cas.services.${service_class}",
    'name'                   => $title,
    'serviceId'              => $service_id,
    'attributeReleasePolicy' => {'@class' => "org.apereo.cas.services.${release_policy}"},
    'id'                     => $id,
    'accessStrategy'         => $_access_strategy,
  } + $multifactor_policy

  $data = $properties.empty ? {
    true    => $base_data,
    default => $base_data + {'properties' => $properties},
  }
  file {"${apereo_cas::services_dir}/${title}-${id}.json":
    ensure  => file,
    content => $data.to_json()
  }
}
