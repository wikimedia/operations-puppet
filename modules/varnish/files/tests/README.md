# Vagrant

Below are the steps to run VTC tests in Vagrant:

* Start your test instance.
```
  vagrant up
```
* SSH into your newly created instance.
```
vagrant ssh
```
* Inside your instance the Export your Jenkins username and your Jenkins token.
```bash
export JENKINS_USERNAME=<YOUR_JENKINS_USERNAME>
export JENKINS_API_TOKEN=<YOUR_JENKINS_API_TOKEN>
```
* You can then execute the run script passing it your preferred cache server's hostname and the change ID that you want to test.
```
  ./run.sh cp4022.ulsfo.wmnet 506868
```
* You can as well run all the above commands in a single execution after you have started your test instance.
```bash
vagrant ssh -c "export JENKINS_USERNAME=<JENKINS_USERNAME> ; export JENKINS_API_TOKEN=<JENKINS_API_TOKEN> ; cd /vagrant/ ; ./run.py cp4022.ulsfo.wmnet 506868 /utils/pcc
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

# Docker Script
You can also runt the test inside a docker container by executing the `docker_run.sh`. For the script to run, you will have to pass 2 mandatory arguments as depicted below. You are also required to export your `Jenkins` credentials that will in turn be used inside the container.
```
./docker_run.sh HOSTNAME CHANGE_ID
```
The above command will build you a test image, if it does not already exits, it will then start a container in which the varnish tests will be run. Once it is done with the test, it will copy the results to your local `tmp` folder for your review; a summary of the test results is also printed in your screen.

### Examples
```
./docker_run.sh cp4022.ulsfo.wmnet 506868
```
When run with `sudo`, you can execute as below.
```
sudo JENKINS_USERNAME=myuser JENKINS_API_TOKEN=mytoken ./docker_run.sh cp4022.ulsfo.wmnet 506868
```