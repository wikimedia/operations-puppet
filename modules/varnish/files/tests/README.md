# Docker Script
You can run your Varnish tests inside a docker container by executing the [docker_run.sh](docker_run.sh) file. For the script to run, you will have to pass 2 mandatory arguments as depicted below. You are also required to export your `Jenkins` credentials that will in turn be used inside the container.

* Install Docker. (Note that `apt install docker` is incorrect.)
```bash
sudo apt install docker.io
```
* Export your Jenkins credentials i.e username and token.
```bash
export JENKINS_USERNAME=<YOUR_JENKINS_USERNAME>
export JENKINS_API_TOKEN=<YOUR_JENKINS_API_TOKEN>
```
* Run the docker script by passing your targeted cp host and a change ID.
```
./docker_run.sh HOST CHANGE_ID
```
The above command will build a test image. If it does not already exist, then it starts a container in which the varnish tests will be run. When done running the tests successfully, a copy the test results is dumped into your local `tmp` folder for your review. Also printed on your screen is summary of the test results.

### Examples
```
./docker_run.sh cp4022.ulsfo.wmnet 506868
```
When run with `sudo`, you can execute as below.
```
sudo JENKINS_USERNAME=myuser JENKINS_API_TOKEN=mytoken ./docker_run.sh cp4022.ulsfo.wmnet 506868
```
# Debian Host
Alternatively, on a Debian system, you can install the following packages from https://wikitech.wikimedia.org/wiki/APT_repository:

- varnish
- varnish-modules
- libvmod-netmapper
- libmaxminddb-dev ( also needs to be installed, any version will do).

Use run.py to test a Gerrit changeset against a given cache host.
For example:
```
  ./run.py cp4022.ulsfo.wmnet 506868
```
