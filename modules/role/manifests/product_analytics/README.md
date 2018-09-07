# Roles for Product Analytics team

Various VM configurations for use by Data Analysts on the [Product Analytics](https://www.mediawiki.org/wiki/Product_Analytics) team in Wikimedia Audiences.

## Roles

- **Statistical Computing** (these require Debian)
    - `base`: configures essential packages/libraries
        - **R packages**: Rcpp, 'tidyverse' and 'tidymodels' collections
        - **Python libraries**: Cython, NumPy, Pandas, SciPy, H5Py
    - `bayes`: configures the instance for Bayesian data analysis
        - **R packages**: RStan, RStanARM, brms, 'tidybayes' collection
        - **Python libraries**: PyStan, PyMC3, TensorFlow Probability, Edward
    - `forecaster`: configures the instance for time series analysis
        - **R packages**: forecast, Prophet, bsts
        - **Python libraries**: Prophet
    - `learner`: configures the instance for machine learning; requires Stretch or newer, *not* available for Jessie
        - **R packages**: caret, mlr, xgboost, and several others ML packages
        - **Python libraries**: Scikit-Learn
    - `deep_learner`: configures the instance for deep learning (DL) via:
        - [TensorFlow](https://www.tensorflow.org/) including [R interface](https://tensorflow.rstudio.com/)
        - [Keras](https://keras.io/) including [R interface](https://keras.rstudio.com/)
        - [Caffe](http://caffe.berkeleyvision.org/)
        - [MXNet](https://mxnet.incubator.apache.org/)
    - `allstar_cruncher`: configures the instance for Bayesian stats, ML/DL, and forecasting; requires Stretch or newer, *not* available for Jessie

**Notes**: The computing roles require Debian because the R that comes with Trusty is too outdated. Also the roles that use `profile::product_analytics::machine_learning` require Stretch or newer version of Debian due to `python3-sklearn`.

## Future work

- More DL libraries
    - [CNTK](https://docs.microsoft.com/en-us/cognitive-toolkit/setup-linux-python)
    - [PyTorch](http://pytorch.org/)
    - [Caffe2](https://caffe2.ai/)
- [h2o](https://github.com/h2oai/h2o-3) ML library support

## Maintenance

These roles (and the profiles they use) are maintained by the following Wikimedia Foundation staff:

- [Mikhail Popov](https://meta.wikimedia.org/wiki/User:MPopov_(WMF))
