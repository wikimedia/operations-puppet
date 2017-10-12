# Roles for Discovery Front-end and Search Platform teams

## Roles

- **Discovery Dashboards** (these require Ubuntu)
    - *dashboards*: sets up the dashboards using the "master" versions
    - *beta_dashboards*: sets up the dashboards using the "develop" versions
- **Statistical Computing** (these require Debian)
    - *bayes*: configures the instance for Bayesian inference using MCMC
    - *forecaster*: configures the instance for time series forecasting
    - *learner*: configures the instance for machine learning
        - requires Stretch or newer, not available for Jessie
    - *allstar_cruncher*: configures the instance for all three purposes
        - requires Stretch or newer, not available for Jessie

**Notes**: Discovery Dashboards require Ubuntu because that's the only OS we
have Shiny Server available for. There is a ticket to build that package for
Debian: [T168967](https://phabricator.wikimedia.org/T168967). The computing
roles require Debian because the R that comes with Trusty is too outdated. Also
the roles that use `profile::discovery_computing::machine_learning` require
Stretch or newer version of Debian due to `python3-sklearn`.

## Future work

It'd be great to have a computing role that configures the instance for deep
learning (DL), but that would require Puppetized `pip` commands because Pip is
the only way to install TensorFlow, PyTorch, and other DL frameworks.

## Maintenance

These roles (and the profiles they use) are maintained by the following
Wikimedia Foundation staff:

- [Mikhail Popov](https://meta.wikimedia.org/wiki/User:MPopov_(WMF))
- [Chelsy Xie](https://meta.wikimedia.org/wiki/User:CXie_(WMF))
- [Guillaume Lederrey](https://meta.wikimedia.org/wiki/User:GLederrey_(WMF))
