package short_as_long

import "core:os"
import "core:fmt"
import "getargs"

main :: proc()
{
	argparser := getargs.make_getargs()
	getargs.add_arg(&argparser, "d", "", getargs.Optarg_Option.None)
	getargs.add_arg(&argparser, "f", "", getargs.Optarg_Option.None)
	getargs.add_arg(&argparser, "second", "", getargs.Optarg_Option.None)
	getargs.add_arg(&argparser, "number", "", getargs.Optarg_Option.Required)
	getargs.add_arg(&argparser, "special", "", getargs.Optarg_Option.Optional)

	if getargs.read_args(&argparser, os.args) {
		os.exit(1)
	}

	if (getargs.get_flag(&argparser, "d")) {
		fmt.println("dynamic flagged")
	}
	if (getargs.get_flag(&argparser, "f")) {
		fmt.println("first flagged")
	}
	if (getargs.get_flag(&argparser, "second")) {
		fmt.println("second flagged")
	}

	payload, was_flagged := getargs.get_payload(&argparser, "number")
	if (was_flagged) {
		fmt.printf("number flagged with payload `%s'\n", payload)
	}
	payload, was_flagged = getargs.get_payload(&argparser, "special")
	if (was_flagged) {
		fmt.printf("special flagged with payload `%s'\n", payload)
	}
}

