#!/usr/bin/python
"""
Dump info about all instances in all projects to a JSON file
"""
import yaml
import json
import requests

import mwopenstackclients

all_images = None


def get_image_name(clients, id):
    """
    Find name of an image with given id

    Caches it in image_name_cache to not kill the nova API with repeat requests

    client is a novaclient object with access to the image objects
    id is the uuid of the image being fetched

    Returns name of the image, or None if it can't be found
    """
    global all_images

    if not all_images:
        global_images = clients.globalimages()
        all_images = {image.id: image for image in global_images}

    if id in all_images:
        return all_images[id].name
    else:
        return None


def get_enc_info(api_host, project, instance):
    """
    Fetch information from ENC API for given instance in project

    Returns the output of the ENC API, which is a dict containing
    at least two keys - 'roles' and 'hiera'.

    api_host is the host where the ENC API is running (on port 8100)
    project is the name of the project the instance is in
    instance is the name of the instance (just name, not fqdn)
    """
    url = 'http://{host}:8100/v1/{project}/node/{instance}'.format(
        host=api_host,
        project=project,
        instance=instance + '.' + project + '.eqiad.wmflabs',
    )
    return yaml.safe_load(requests.get(url).text)


def main():
    with open('/etc/instance-dumper.yaml') as f:
        config = yaml.safe_load(f)

    clients = mwopenstackclients.Clients(envfile='/etc/novaobserver.yaml')
    servers = clients.allinstances()

    data = {}
    for s in servers:
        server_info = {
            'name': s.name,
            'created_by': s.user_id,
            'created_at': s.created,
            'status': s.status,
            'project': s.tenant_id,
            'ips': s.networks['public'],
            'image': get_image_name(clients, s.image['id']),
        }
        server_info.update(get_enc_info(config['enc_host'], s.tenant_id, s.name))
        if s.tenant_id in data:
            data[s.tenant_id].append(server_info)
        else:
            data[s.tenant_id] = [server_info]

    with open(config['output_path'], 'w') as f:
        json.dump(data, f)


if __name__ == '__main__':
    main()
