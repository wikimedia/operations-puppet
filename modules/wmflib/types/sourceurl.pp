# puppet file resource basic validator
type Wmflib::Sourceurl = Variant[Undef, Pattern[/\Apuppet:\/\/\/modules\/.*/]]
