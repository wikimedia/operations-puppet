# set a salt grain on a node
class salt::setgrain( $grain_name, $grain_value ) {

    salt::grain { $grain_name: value => $grain_value }

}
