# SPDX-License-Identifier: Apache-2.0

# Convenience type for valid ./modules/alerts/files/deploy.py --transformations values
type Alerts::Deploy::Transform = Enum['page-is-critical', 'page-is-warning']
