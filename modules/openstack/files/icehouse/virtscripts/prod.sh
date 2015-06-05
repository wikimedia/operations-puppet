#!/bin/bash
#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///modules/openstack/icehouse/virtscripts/prod.sh
#####################################################################

set -x

# Using token auth env variables
SERVICE_ENDPOINT=http://labcontrol1001.wikimedia.org:35357/v2.0/
SERVICE_TOKEN=<redacted>

# ENDPOINT URLS
NOVA_PUBLIC_URL="http://labnet1001.eqiad.wmnet:8774/v2/\$(tenant_id)s"
NOVA_ADMIN_URL=$NOVA_PUBLIC_URL
NOVA_INTERNAL_URL=$NOVA_PUBLIC_URL

GLANCE_PUBLIC_URL="http://labcontrol1001.wikimedia.org:9292/v1"
GLANCE_ADMIN_URL=$GLANCE_PUBLIC_URL
GLANCE_INTERNAL_URL=$GLANCE_PUBLIC_URL

KEYSTONE_PUBLIC_URL="http://labcontrol1001.wikimedia.org:5000/v2.0"
KEYSTONE_ADMIN_URL="http://labcontrol1001.wikimedia.org:35357/v2.0"
KEYSTONE_INTERNAL_URL=$KEYSTONE_PUBLIC_URL

NEUTRON_PUBLIC_URL="http://labcontrol1001.wikimedia.org:9696"
NEUTRON_ADMIN_URL=$NEUTRON_PUBLIC_URL
NEUTRON_INTERNAL_URL=$NEUTRON_PUBLIC_URL

# Create required services
keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT service-create --name nova --type compute --description 'OpenStack Compute Service'
keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT service-create --name glance --type image --description 'OpenStack Image Service'
keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT service-create --name keystone --type identity --description 'OpenStack Identity Service'
#keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT service-create --name neutron --type network --description 'OpenStack Network Service'

# Create endpoints on the services
#for S in NOVA GLANCE KEYSTONE NEUTRON
for S in NOVA GLANCE KEYSTONE
do
	ID=$(keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT service-list | grep -i "\ $S\ " | awk '{print $2}')
	PUBLIC=$(eval echo \$${S}_PUBLIC_URL)
	ADMIN=$(eval echo \$${S}_ADMIN_URL)
	INTERNAL=$(eval echo \$${S}_INTERNAL_URL)
	keystone --token $SERVICE_TOKEN --os-endpoint $SERVICE_ENDPOINT endpoint-create --region eqiad --service_id $ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL
done
