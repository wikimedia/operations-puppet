#!/bin/bash
#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///files/openstack/folsom/virtscripts/prod.sh
#####################################################################

set -x

# Using token auth env variables
SERVICE_ENDPOINT=http://virt0.wikimedia.org:35357/v2.0/
SERVICE_TOKEN=gooz1ooZa4ohtee

# ENDPOINT URLS
NOVA_PUBLIC_URL="http://virt2.pmtpa.wmnet:8774/v2/\$(tenant_id)s"
NOVA_ADMIN_URL=$NOVA_PUBLIC_URL
NOVA_INTERNAL_URL=$NOVA_PUBLIC_URL

GLANCE_PUBLIC_URL="http://virt0.wikimedia.org:9292/v1"
GLANCE_ADMIN_URL=$GLANCE_PUBLIC_URL
GLANCE_INTERNAL_URL=$GLANCE_PUBLIC_URL

KEYSTONE_PUBLIC_URL="http://virt0.wikimedia.org:5000/v2.0"
KEYSTONE_ADMIN_URL="http://virt0.wikimedia.org:35357/v2.0"
KEYSTONE_INTERNAL_URL=$KEYSTONE_PUBLIC_URL

PROXY_PUBLIC_URL="http://dynamicproxy/dynamicproxy-api/v1"
PROXY_ADMIN_URL="http://dynamicproxy/dynamicproxy-api/v1"
PROXY_INTERNAL_URL=$PROXY_PUBLIC_URL


# Create required services
keystone --token $SERVICE_TOKEN --endpoint $SERVICE_ENDPOINT service-create --name nova --type compute --description 'OpenStack Compute Service'
keystone --token $SERVICE_TOKEN --endpoint $SERVICE_ENDPOINT service-create --name glance --type image --description 'OpenStack Image Service'
keystone --token $SERVICE_TOKEN --endpoint $SERVICE_ENDPOINT service-create --name keystone --type identity --description 'OpenStack Identity Service'
keystone --token $SERVICE_TOKEN --endpoint $SERVICE_ENDPOINT service-create --name proxy --type proxy --description 'Dynamic Proxy Service'

# Create endpoints on the services
for S in NOVA GLANCE KEYSTONE PROXY
do
	ID=$(keystone --token $SERVICE_TOKEN --endpoint $SERVICE_ENDPOINT service-list | grep -i "\ $S\ " | awk '{print $2}')
	PUBLIC=$(eval echo \$${S}_PUBLIC_URL)
	ADMIN=$(eval echo \$${S}_ADMIN_URL)
	INTERNAL=$(eval echo \$${S}_INTERNAL_URL)
	keystone --token $SERVICE_TOKEN --endpoint $SERVICE_ENDPOINT endpoint-create --region pmtpa --service_id $ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL
done
