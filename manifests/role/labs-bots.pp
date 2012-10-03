class role::labs-bots-application {
    class{ 'labs-bots::common': }
}

class role::labs-bots-mysql {
    class{ 'labs-bots::mysql': }
}

class role::labs-bots-userweb {
    class{ 'labs-bots::userweb': }
}
