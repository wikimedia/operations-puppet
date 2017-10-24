# Provision for deep learning
#
# Install and configure R and install Discovery-specific essential R/Python2
# packages for learning with deep neural networks. The R interfaces are
# available through RStudio's reticulate (https://rstudio.github.io/reticulate/)
#
# filtertags: labs-project-discovery-stats
class profile::discovery_computing::deep_learning {
    require profile::discovery_computing::base

    $pkgs = [
        'python-h5py',      # Python interface to HDF5 (required for saving Keras models to disk)
        'python-html5lib',  # HTML parser (required for TensorFlow)
        'caffe-cpu',        # Fast, open framework for Deep Learning
        'python-caffe-cpu', # Python3 interface of Caffe
        'python-skimage',   # Python 3 modules for image processing
    ]
    require_package($pkgs)

    package { 'tensorflow':
        ensure   => 'installed',
        require  => [
            Package['python-dev'],
            Package['python-numpy'],
            Package['python-wheel']
        ],
        provider => 'pip',
    }
    package { 'keras':
        ensure   => 'installed',
        require  => [
            Package['python-h5py'],
            Package['tensorflow']
        ],
        provider => 'pip',
    }
    package { 'mxnet':
        ensure   => 'installed',
        require  => [
          Package['python-numpy'],
          Package['python-requests']
        ],
        provider => 'pip',
    }

    $r_packages = [
        'keras',   # also installs tensorflow R package
        'deepnet', # deep learning toolkit in R
        'darch'    # Deep Architectures and Restricted Boltzmann Machines
    ]
    r_lang::cran { $r_packages:
        require => [
            Package['python-dev'],
            Package['keras'] # implied dependence on tensorflow
        ],
    }

}
