# SPDX-License-Identifier: Apache-2.0

# Copyright 2023 Andrew Bogott for the Wikimedia Foundation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from oslo_config import cfg
from keystoneauth1.identity.v3 import Password as KeystonePassword
from keystoneauth1 import session as keystone_session
from keystoneclient.v3 import client as keystone_client


def project_name_from_id(keystoneclient, project_id):
    project = keystoneclient.projects.get(project_id)
    return project.name


def get_keystone_session(project_name="admin"):
    auth = KeystonePassword(
        auth_url=cfg.CONF["keystone_authtoken"].www_authenticate_uri,
        username=cfg.CONF["keystone_authtoken"].username,
        password=cfg.CONF["keystone_authtoken"].password,
        user_domain_name="Default",
        project_domain_name="Default",
        project_name=project_name,
    )

    return keystone_session.Session(auth=auth)


def get_keystone_client(project_name="admin"):
    return keystone_client.Client(
        session=get_keystone_session(), interface="public", connect_retries=5
    )
