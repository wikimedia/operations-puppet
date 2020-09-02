type Cfssl::Auth_key = Struct[{
    key => Pattern[/^[a-fA-F0-9]{16}$/],
    type => Enum['standard'],
}]
