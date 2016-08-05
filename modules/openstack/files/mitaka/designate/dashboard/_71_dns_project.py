# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

from designatedashboard import exceptions

# The name of the panel to be added to HORIZON_CONFIG. Required.
PANEL = 'domains'
# The name of the dashboard the PANEL associated with. Required.
PANEL_DASHBOARD = 'project'
# The name of the panel group the PANEL is associated with.
PANEL_GROUP = 'dns'

ADD_EXCEPTIONS = {
    'recoverable': exceptions.RECOVERABLE,
    'not_found': exceptions.NOT_FOUND,
    'unauthorized': exceptions.UNAUTHORIZED,
}

# Python panel class of the PANEL to be added.
ADD_PANEL = (
    'designatedashboard.dashboards.project.dns_domains.panel.DNSDomains')
