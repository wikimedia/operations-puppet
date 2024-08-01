#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -x

# Using token auth env variables
SERVICE_ENDPOINT=https://openstack.eqiad1.wikimediacloud.org:25357/v2.0/
SERVICE_TOKEN='<redacted>'

# ENDPOINT URLS
NOVA_PUBLIC_URL="https://openstack.eqiad1.wikimediacloud.org:28774/v2.0/\$(tenant_id)s"
NOVA_ADMIN_URL=$NOVA_PUBLIC_URL
NOVA_INTERNAL_URL=$NOVA_PUBLIC_URL

GLANCE_PUBLIC_URL="https://openstack.eqiad1.wikimediacloud.org:29292"
GLANCE_ADMIN_URL=$GLANCE_PUBLIC_URL
GLANCE_INTERNAL_URL=$GLANCE_PUBLIC_URL

KEYSTONE_PUBLIC_URL="https://openstack.eqiad1.wikimediacloud.org:25000/v2.0"
KEYSTONE_ADMIN_URL="https://openstack.eqiad1.wikimediacloud.org:25357/v2.0"
KEYSTONE_INTERNAL_URL=$KEYSTONE_PUBLIC_URL

# Create required services
keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT service-create --name nova --type compute --description 'OpenStack Compute Service'
keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT service-create --name glance --type image --description 'OpenStack Image Service'
keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT service-create --name keystone --type identity --description 'OpenStack Identity Service'

for S in NOVA GLANCE KEYSTONE
do
	ID=$(keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT service-list | grep -i "\ $S\ " | awk '{print $2}')
	PUBLIC=$(eval echo \$${S}_PUBLIC_URL)
	ADMIN=$(eval echo \$${S}_ADMIN_URL)
	INTERNAL=$(eval echo \$${S}_INTERNAL_URL)
	keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT endpoint-create --region eqiad --service_id $ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL
done
