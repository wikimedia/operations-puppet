# Provision for machine learning
#
# Install and configure R and install Discovery-specific essential R/Python
# packages for machine learning.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this profile (and any profiles or
# roles that include it) to instances running on Debian (Stretch or newer).
#
# filtertags: labs-project-discovery-stats
class profile::discovery_computing::machine_learning {
    require profile::discovery_computing::base

    $python_packages = [
        'python3-sklearn' # Python modules for machine learning and data mining
    ]
    require_package($python_packages)

    $r_packages = [
        # Frameworks/utilities:
        'caret',           # Functions for training
        'MLmetrics',       # Evaluation Metrics
        'mlbench',         # Benchmark Problems
        'mlr',             # ML framework/interface similar to caret
        # Supervised learning algorithms:
        'xgboost',         # Extreme Gradient Boosting
        'C50',             # C5.0 Decision Trees and Rule-Based Models
        'klaR',            # Classification and visualization
        'randomForest',    # Random Forests
        'randomForestSRC', # Random Forests for Survival
        'e1071',           # Misc models (e.g. Naive Bayes)
        'neuralnet',       # Neural Networks
        'elasticnet',      # Elastic-Net for Sparse Estimation and Sparse PCA
        'glmnet',          # Lasso and Elastic-Net Regularized Generalized Linear Models
        # Unsupervised learning algorithms:
        'mclust',          # Model-Based Clustering, Classification, and Density Estimation
        'bclust'           # Bayesian Hierarchical Clustering
    ]
    r_lang::cran { $r_packages:
        require => R_lang::Cran['data.table'],
    }

    $bioconductor_packages = [
        'RBGL',
        'Rgraphviz'
    ]
    $r_lang::bioc { $bioconductor_packages: }

    r_lang::cran { 'bnclassify':
        require => [
            R_lang::Bioc['RBGL'],
            R_lang::Bioc['Rgraphviz']
        ],
    }

}
