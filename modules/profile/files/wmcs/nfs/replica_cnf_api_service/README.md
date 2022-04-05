<!-- SPDX-License-Identifier: Apache-2.0 -->
#### This REST API service is used to manage toolforge replica.my.cnf.
#### It decouples the functionality of reading and writing replica.my.cnf files away from this repository and into its server environment.

# To Deploy
* Setup Nginx
* Setup gunicorn
* Run setup.sh

## Setup Nginx

* If you don't already have Nginx running on your server, you can follow [this link](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04) to setup Nginx.

* When you are done setting up Nginx, you can then add the below server block to your Nginx file.

```
log_format private '[$time_local] "$request" $status $body_bytes_sent "$http_referer"';

server {
    listen 80;
    server_name <domain name>;
    access_log /var/log/nginx/access.log private;

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/<username>/replica_cnf_api_service/replica_cnf_api_service.sock;
    }
}
```
> **_NOTE:_** Remember to replace `<domain name>` and `<username>` with the appropriate values for your server.

## Setup gunicorn

* Follow [this link](https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-gunicorn-and-nginx-on-ubuntu-20-04) to see how to setup gunicorn for this project.
* For this project, the important part is to remember to use the below snippet for the systemd setup:

```
[Unit]
Description=Gunicorn instance to serve replica_cnf_api_service
After=network.target

[Service]
User=<username>
Group=www-data
WorkingDirectory=/home/<username>/replica_cnf_api_service
Environment="PATH=/home/<username>/replica_cnf_api_service/venv/bin"
ExecStart=/home/<username>/replica_cnf_api_service/venv/bin/gunicorn "replica_cnf_api_service:create_app()" --threads=3 --timeout 155 --bind unix:replica_cnf_api_service.sock -m 007
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
```

> **_NOTE:_** Always remember to replace `<username>` with the appropriate value for your server. Also, you should name your systemd file replica_cnf_api_service.service, or else an attempt to reload the server by the setup script will probably fail.

## Run setup.sh

* In the same directory containing this readme file, you will find a setup.sh script, run the script with `sudo ./setup.sh`
* create the path `/test_srv/shared/test_tools/home/test_tool` for testing purposes.
* the curl command below can be used to start interacting with your server over HTTP:
```
curl -X POST -H 'Content-Type: application/json' -d '{"mysql_username":"Raymond_Ndibe","password":"my_password","file_path":"/test_srv/shared/test_tools/home/test_tool/replica.my.cnf","uid":0}'  http://localhost:8000/v1/write-replica-cnf
```

> **_NOTE:_** This readme is still a work in progress. The purpose of this readme is to make it easy for anyone to begin testing this service. However, everything outlined in this readme might not work exactly like it is outlined here.


