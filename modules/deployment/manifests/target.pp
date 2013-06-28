define deployment::target() {
    salt::grain { "deployment_target_$name":
        grain => "deployment_target",
        value => $name;
    }
}
