package gnu_style

import "core:os"
import "core:fmt"
import "getargs"

main :: proc()
{
	argparser := getargs.make_getargs()
	getargs.add_arg(&argparser, "d", "dynamic", getargs.Optarg_Option.None)
	getargs.add_arg(&argparser, "f", "first", getargs.Optarg_Option.None)
	getargs.add_arg(&argparser, "s", "second", getargs.Optarg_Option.None)
	getargs.add_arg(&argparser, "n", "number", getargs.Optarg_Option.Required)
	getargs.add_arg(&argparser, "S", "special", getargs.Optarg_Option.Optional)

	if getargs.read_args(&argparser, os.args) {
		os.exit(1)
	}

	if (getargs.get_flag(&argparser, "dynamic")) {
		fmt.println("dynamic flagged")
	}
	if (getargs.get_flag(&argparser, "f")) {
		fmt.println("first flagged")
	}
	if (getargs.get_flag(&argparser, "s")) {
		fmt.println("second flagged")
	}
	
	payload, was_flagged := getargs.get_payload(&argparser, "n")
	if (was_flagged) {
		fmt.printf("number flagged with payload `%s'\n", payload)
	}

	payload, was_flagged = getargs.get_payload(&argparser, "special")
	if (was_flagged) {
		fmt.printf("special flagged with payload `%s'\n", payload)
	}
}

