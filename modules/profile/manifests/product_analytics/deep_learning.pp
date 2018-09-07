# Provision for deep learning
#
# Install and configure R and install Product Analytics-specific essential
# R/Python2 packages for learning with deep neural networks. The R interfaces
# are available through RStudio's reticulate package.
#
# filtertags: labs-project-discovery-stats
class profile::product_analytics::deep_learning {
    require profile::product_analytics::base

    $pkgs = [
        'python-html5lib',   # HTML parser (required for TensorFlow)
        'caffe-cpu',         # Fast, open framework for Deep Learning
        'python3-caffe-cpu', # Python3 interface to Caffe
        'python-skimage',    # Python2 modules for image processing
        'python3-skimage',   # Python3 modules for image processing
    ]
    require_package($pkgs)

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
        'keras',   # R interface to Python library 'Keras'
        'deepnet', # deep learning toolkit in R
        'darch'    # Deep Architectures and Restricted Boltzmann Machines
    ]
    r_lang::cran { $r_packages:
        require => [
            Package['python-dev'],
            Package['keras']
        ],
    }

}
