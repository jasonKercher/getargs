package gnu_style

import "core:os"
import "core:fmt"
import "getargs"

main :: proc()
{
	argparser := getargs.make_getargs({.No_Dash})
	getargs.add_arg(&argparser, "d", "dynamic", .None)
	getargs.add_arg(&argparser, "f", "first", .None)
	getargs.add_arg(&argparser, "s", "second", .None)
	getargs.add_arg(&argparser, "n", "number", .Required)
	getargs.add_arg(&argparser, "S", "special", .Optional)

	getargs.read_args(&argparser, os.args)

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

	for ; argparser.arg_idx < len(os.args) ; argparser.arg_idx += 1 {
		fmt.printf("Additional argument: `%s'\n", os.args[argparser.arg_idx])
	}

	getargs.destroy(&argparser)
}

