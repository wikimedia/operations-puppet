# Varnish tests

## Containers

You can run your Varnish tests inside a container by executing the [docker_run.sh](docker_run.sh) file. For the script to run, must export your `Jenkins` credentials which will in turn be used inside the container, and pass 2 mandatory arguments as depicted below.

* Install Docker or Podman. (Note that `apt install docker` is incorrect.)
* Export your Jenkins credentials i.e username and token.
```bash
export JENKINS_USERNAME=<YOUR_JENKINS_USERNAME>
export JENKINS_API_TOKEN=<YOUR_JENKINS_API_TOKEN>
```
* Run the docker script by passing your targeted cp host and a change ID.
```
./docker_run.sh HOST CHANGE_ID
```
The above command will build a test image. If it does not already exist, then it starts a container in which the Varnish tests will be run.

### Example: Compile catalog and run all tests

```
./docker_run.sh cp1102.eqiad.wmnet 1184126
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

## Debian host

Alternatively, on a Debian system, you can install the following packages from https://wikitech.wikimedia.org/wiki/APT_repository:

- varnish
- varnish-modules
- libvmod-netmapper
- libmaxminddb-dev (also needs to be installed, any version will do).

Use run.py to test a Gerrit changeset against a given cache host.
For example:
```
  ./run.py cp4022.ulsfo.wmnet 506868
```
