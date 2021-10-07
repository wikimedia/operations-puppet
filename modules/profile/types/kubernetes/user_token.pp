type Profile::Kubernetes::User_token = Struct[{
    'token'        => String,
    'groups'       => Optional[Array[String]],
    'constrain_to' => Optional[String]
}]
