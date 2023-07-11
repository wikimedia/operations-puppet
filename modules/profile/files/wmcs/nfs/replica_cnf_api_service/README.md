<!-- SPDX-License-Identifier: Apache-2.0 -->

> **_NOTE:_** This readme is outdated and any attempt to follow the instructions
> in this readme will probably not work out or end up behaving unexpectedly.
> Having said that, the purpose of this readme is to make it easy for anyone to
> begin testing this service. However, everything outlined in this readme might
> not work exactly like it is outlined here.

#### This REST API service is used to manage toolforge replica.my.cnf.

#### It decouples the functionality of reading and writing replica.my.cnf files away from this repository and into its server environment.

# To Deploy

- Use puppet :)

# To test locally

There's two very different suites of tests, unit tests (written with pytest) and
the functional tests (written with bats). In this README we will run both,
included in tox.

## Install dependencies

Currently the application has to run on buster nodes, so it has to be backwards
compatible with python 3.7.

## Run the tests locally

### Install python 3.7

You have to setup python 3.7 whichever way you prefer :), this uses pyenv:

```
pyenv install 3.7
pyenv local 3.7
pyenv virtualenv mytestingvenv
pyenv activate mytestingvenv
```

### Run the tests

Now you can use the virtualenv above (or your preferred method) to install tox
and run the tests:

```
pip install tox
tox -e wmcs-replica_cnf_api_service
```

## Run the tests as CI would

For this you can just use the common script:

```
utils/run_ci_locally.sh
```
