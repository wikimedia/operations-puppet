# PDF rendering servers (RT-1100,RT-1101)

class role::pdf {
	system_role { "role::pdf": description => "PDF rendering server" }

	include standard,
		misc::pdf::fonts
}
