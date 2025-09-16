# Varnish tests

## Docker container

You can run your Varnish tests inside a docker container by executing the [docker_run.sh](docker_run.sh) file. For the script to run, must export your `Jenkins` credentials which will in turn be used inside the container, and pass 2 mandatory arguments as depicted below.

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
The above command will build a test image. If it does not already exist, then it starts a container in which the Varnish tests will be run. When the test run is complete, a copy the test results is dumped into your local `/tmp` folder for your review. Also printed on your screen is the passed/failed test count.

### Example: Compile catalog and run all tests

```
./docker_run.sh cp1102.eqiad.wmnet 1184126

[*] running PCC for change 1187464...
  PCC URL: https://puppet-compiler.wmflabs.org/output/1184126/7413/

[*] Finding cluster...
  cp1102.eqiad.wmnet is a cache_text host

[*] Running varnishtest (this might take a while)...
  sudo varnishtest -k … /wikimedia/varnish/text/*.vtc

0 tests failed, 0 tests skipped, 21 tests passed
Test output saved to /tmp/tmpbtbzgrfl
If you want to fix your tests and re-run without recompiling pcc, run as follows:
python3 run.py cp1102.eqiad.wmnet https://puppet-compiler.wmflabs.org/output/1184126/7413/

…
Results copied to /var/folders/_5/khc4z6kx4nbg4mn5wxyzbsn40000gn/T/vtcresults.4gkOJEYHRU for your reference.
```

If using Docker on Linux (i.e. rootless Podman, or Docker Desktop on Mac), you may need to run use `sudo`:
```
sudo JENKINS_USERNAME=myuser JENKINS_API_TOKEN=mytoken ./docker_run.sh cp4022.ulsfo.wmnet 506868
```

### Example: Re-run without waiting for PCC

If you've only changed test files since your last full PCC run,
you can get a much quicker response by passing the PCC url from your previous run
and pass it in place of the change number:

```
./docker_run.sh cp1102.eqiad.wmnet https://puppet-compiler.wmflabs.org/output/1184126/7413/
```

### Example: Run only certain tests

By default, all `text/*.vtc` or `upload/*.vtc` test files will be run.

You can iterate on a specific test more quickly by passing a test filename as the last argument.

* A path may be passed, to allow for tab completion (only the basename is used).
* A prefix may be passed, to remove need for escaping or quoting glob stars.

The following are equivalent:

```
./docker_run.sh cp1102.eqiad.wmnet 1184126 /path/to/text/08-mobile-hostnames-rewrite.vtc
./docker_run.sh cp1102.eqiad.wmnet 1184126 text/08-mobile-hostnames-rewrite.vtc
./docker_run.sh cp1102.eqiad.wmnet 1184126 ./08-mobile-hostnames-rewrite.vtc
./docker_run.sh cp1102.eqiad.wmnet 1184126 08-mobile-hostnames-rewrite.vtc
./docker_run.sh cp1102.eqiad.wmnet 1184126 08-mobile-hostnames-rewrite.vtc.bak
./docker_run.sh cp1102.eqiad.wmnet 1184126 08-mobile-hostnames-rewrite.x.y
./docker_run.sh cp1102.eqiad.wmnet 1184126 08-mobile
./docker_run.sh cp1102.eqiad.wmnet 1184126 '08*'
./docker_run.sh cp1102.eqiad.wmnet 1184126 08
```
```
$ ./docker_run.sh cp1102.eqiad.wmnet 1184126 text/08-mobile-hostnames-rewrite.vtc

[*] Finding cluster...
  cp1102.eqiad.wmnet is a cache_text host

[*] Running varnishtest (this might take a while)...
  sudo varnishtest -k … /wikimedia/varnish/text/08-mobile-hostnames-rewrite*.vtc

0 tests failed, 0 tests skipped, 1 tests passed
```

## Debian host

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
