# Role class for kartotherian
class role::kartotherian {

    system::role { 'role::kartotherian':
        description => 'A vector and raster map tile generator service',
    }

    include ::kartotherian
}

