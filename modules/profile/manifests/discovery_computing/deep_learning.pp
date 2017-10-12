# Provision for deep learning
#
# Install and configure R and install Discovery-specific essential R/Python
# packages for learning with deep neural networks. The R interfaces are
# available through RStudio's reticulate (https://rstudio.github.io/reticulate/)
#
# filtertags: labs-project-discovery-stats
class profile::discovery_computing::deep_learning {
    require profile::discovery_computing::base

    $pkgs = [
        'python3-h5py',      # Python interface to HDF5 (required for saving Keras models to disk)
        'python3-html5lib',  # HTML parser (required for TensorFlow)
        'caffe-cpu',         # Fast, open framework for Deep Learning
        'python3-caffe-cpu', # Python3 interface of Caffe
        'python3-skimage',   # Python 3 modules for image processing
        'python3-six',       # Python 2 and 3 compatibility library
    ]
    require_package($pkgs)

    package { 'tensorflow':
        ensure   => 'installed',
        require  => [
            Package['python3-dev'],
            Package['python3-numpy'],
            Package['python3-six'],
            Package['python3-wheel']
        ],
        provider => 'pip3',
    }
    package { 'keras':
        ensure   => 'installed',
        require  => [
            Package['python3-h5py'],
            Package['tensorflow']
        ],
        provider => 'pip3',
    }
    package { 'mxnet':
        ensure   => 'installed',
        require  => [
          Package['python3-numpy'],
          Package['python3-requests']
        ],
        provider => 'pip3',
    }

    $r_packages = [
        'keras',   # also installs tensorflow R package
        'deepnet', # deep learning toolkit in R
        'darch'    # Deep Architectures and Restricted Boltzmann Machines
    ]
    r_lang::cran { $r_packages:
        require => [
            Package['python3-dev'],
            Package['keras'] # implied dependence on tensorflow
        ],
    }

}
