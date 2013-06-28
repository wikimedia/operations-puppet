class deployment::target($target) {
    salt::grain { "deployment_target_$target":
        grain => "deployment_target",
        value => $target;
    }
}
