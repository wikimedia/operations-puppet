class role::labs-bots-application {
    include 'labs-bots::common'
}

class role::labs-bots-mysql {
    include 'labs-bots::mysql'
}

class role::labs-bots-userweb {
    include 'labs-bots::userweb'
}
