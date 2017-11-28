# Roles for Discovery Front-end and Search Platform teams

## Roles

- **Discovery Dashboards** (these require Ubuntu)
    - `dashboards`: sets up the dashboards using the "master" versions
    - `beta_dashboards`: sets up the dashboards using the "develop" versions
- **Statistical Computing** (these require Debian)
    - `bayes`: configures the instance for Bayesian inference using MCMC
    - `forecaster`: configures the instance for time series forecasting
    - `learner`: configures the instance for machine learning; requires Stretch
      or newer, *not* available for Jessie
    - `deep_learner`: configures the instance for deep learning (DL) via:
        - [TensorFlow](https://www.tensorflow.org/) including [R interface](https://tensorflow.rstudio.com/)
        - [Keras](https://keras.io/) including [R interface](https://keras.rstudio.com/)
        - [Caffe](http://caffe.berkeleyvision.org/)
        - [MXNet](https://mxnet.incubator.apache.org/)
    - `allstar_cruncher`: configures the instance for Bayesian stats, ML/DL,
      and forecasting; requires Stretch or newer, *not* available for Jessie

**Notes**: Discovery Dashboards require Ubuntu because that's the only OS we
have Shiny Server available for. There is a ticket to build that package for
Debian: [T168967](https://phabricator.wikimedia.org/T168967). The computing
roles require Debian because the R that comes with Trusty is too outdated. Also
the roles that use `profile::discovery_computing::machine_learning` require
Stretch or newer version of Debian due to `python3-sklearn`.

## Future work

- More DL libraries
    - [CNTK](https://docs.microsoft.com/en-us/cognitive-toolkit/setup-linux-python)
    - [PyTorch](http://pytorch.org/)
    - [Caffe2](https://caffe2.ai/)
- [h2o](https://github.com/h2oai/h2o-3) ML library support

## Maintenance

These roles (and the profiles they use) are maintained by the following
Wikimedia Foundation staff:

- [Mikhail Popov](https://meta.wikimedia.org/wiki/User:MPopov_(WMF))
- [Chelsy Xie](https://meta.wikimedia.org/wiki/User:CXie_(WMF))
- [Guillaume Lederrey](https://meta.wikimedia.org/wiki/User:GLederrey_(WMF))
