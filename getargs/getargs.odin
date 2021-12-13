package getargs

import "core:fmt"
import "core:os"

@(private="file")
Optarg :: union {
	string,
	bool,
}

Optarg_Option :: enum { None, Required, Optional }

@(private="file")
Argument :: struct {
	option:  Optarg_Option,
	payload: Optarg,
}

/* I do not expect Short_As_Long to be set by a
 * user. But rather, it is a consequence of sending
 * long options as the "short_name"
 */
Getargs_Option :: enum { No_Dash, Short_As_Long }

Getargs :: struct {
	arg_map:  map[string]int,
	arg_vec:  [dynamic]Argument,
	arg_opts: bit_set[Getargs_Option],
	arg_idx:  int,
}

make_getargs :: proc (getargs_opts: bit_set[Getargs_Option] = {}) -> Getargs {
	return Getargs { 
		arg_map=make(map[string]int),
		arg_vec=make([dynamic]Argument),
		arg_idx=1,
		arg_opts=getargs_opts,
	}
}

construct :: proc (self: ^Getargs, getargs_opts: bit_set[Getargs_Option] = {}) {
	self^ = {
		arg_map=make(map[string]int),
		arg_vec=make([dynamic]Argument),
		arg_idx=1,
		arg_opts=getargs_opts,
	}
}

destroy :: proc(self: ^Getargs) {
	delete(self.arg_vec)
	delete(self.arg_map)
}

/* Main method for adding arguments
 * By default, the short name should represent single-dash
 * options (like -d) and the long_name should is the double-
 * dash option (like --dynamic).
 */
add_arg :: proc (self: ^Getargs,
                 short_name: string = "",
		 long_name: string = "",
		 option: Optarg_Option = .None) {

	idx := len(self.arg_vec)
	append(&self.arg_vec, Argument{option=option, payload=false})

	if (len(short_name) > 0) {
		if short_name in self.arg_map {
			fmt.fprintf(os.stderr, "ambiguous option `%s'\n", short_name)
			os.exit(1)
		}

		self.arg_map[short_name] = idx
		if len(short_name) > 1 {
			self.arg_opts += {.Short_As_Long}
		}
	}
	if (len(long_name) > 0) {
		if long_name in self.arg_map {
			fmt.fprintf(os.stderr, "ambiguous option `%s'\n", long_name)
			os.exit(1)
		}
		self.arg_map[long_name] = idx
	}
}

/* Parse short (single byte) args that may be combined (e.g. program -l -s = program -ls) */
@(private="file")
_parse_short_args :: proc(self: ^Getargs, args: []string, dash_offset: int) {
	i := dash_offset
	for ; i < len(args[self.arg_idx]); i += 1 {
		idx, ok := self.arg_map[args[self.arg_idx][i:i+1]]
		if !ok {
			fmt.fprintf(os.stderr, "unable to find arg `%s'\n", args[self.arg_idx][i:i+1])
			os.exit(1)
		}
		
		arg := &self.arg_vec[idx]
		
		if (arg.option == .None) {
			arg.payload = true
			continue
		}

		if i+1 < len(args[self.arg_idx]) {
			arg.payload = args[self.arg_idx][i+1:]
			if arg.option == .Optional || len(arg.payload.(string)) > 0 {
				return
			}
			fmt.fprintf(os.stderr, "`%c' expects an argument\n", args[self.arg_idx][i])
			os.exit(1)
		}

		if self.arg_idx + 1 >= len(args) || args[self.arg_idx+1][0] == '-' {
			if arg.option == .Optional {
				arg.payload = true
				return
			}

			fmt.fprintf(os.stderr, "`%c' expects an argument\n", args[self.arg_idx][i])
			os.exit(1)
		}

		self.arg_idx += 1
		arg.payload = args[self.arg_idx]

		break;
	}
}

/* Parse long args that may use = to delimit the arg from the optarg */
@(private="file")
_parse_long_arg :: proc(self: ^Getargs, args: []string, dash_offset: int) {
	arg_name : string
	has_optarg : bool

	i := dash_offset
	for ; i < len(args[self.arg_idx]); i += 1 {
		if args[self.arg_idx][i] == '=' {
			arg_name = args[self.arg_idx][dash_offset:i]
			has_optarg = true
			break;
		}
	}

	if !has_optarg {
		arg_name = args[self.arg_idx][dash_offset:]
	}

	idx, ok := self.arg_map[arg_name]
	if !ok {
		fmt.fprintf(os.stderr, "unable to find arg `%s'\n", arg_name)
		os.exit(1)
	}

	arg := &self.arg_vec[idx]
	if has_optarg && arg.option == .None {
		fmt.fprintf(os.stderr, "`%s' does not expect an argument\n", arg_name)
		os.exit(1)
	}

	if arg.option == .None {
		arg.payload = true
		return
	}

	if has_optarg {
		arg.payload = args[self.arg_idx][i+1:]
		return
	}

	if self.arg_idx + 1 >= len(args) || args[self.arg_idx+1][0] == '-' {
		if arg.option == .Optional {
			arg.payload = true
			return
		}

		fmt.fprintf(os.stderr, "`%s' expects an argument\n", arg_name)
		os.exit(1)
	}

	self.arg_idx += 1
	arg.payload = args[self.arg_idx]
}

/* Read all args starting at self.arg_idx (1 if unset), and
 * stop as soon as a non-argument is found
 */
read_args :: proc (self: ^Getargs, args : []string) {

	dash_offset: int = 1
	
	if .No_Dash in self.arg_opts {
		dash_offset = 0
	}

	for ; self.arg_idx < len(args); self.arg_idx += 1 {
		/* Check if arg at all */
		if args[self.arg_idx][0] != '-' && .No_Dash not_in self.arg_opts {
			return
		}

		/* Check if long arg */
		if len(args[self.arg_idx]) > dash_offset+1 && args[self.arg_idx][dash_offset] == '-' {
			_parse_long_arg(self, args, dash_offset+1)
			continue
		}

		if .Short_As_Long in self.arg_opts {
			_parse_long_arg(self, args, dash_offset)
		} else {
			_parse_short_args(self, args, dash_offset)
		}
	}
}

/* Whether there is an optarg or not, this proc will return true
 * if the specified argument was provided.
 */
get_flag :: proc (self: ^Getargs, arg_name: string) -> bool {
	idx, ok := self.arg_map[arg_name]
	if !ok {
		fmt.fprintf(os.stderr, "No such argument `%s'\n", arg_name)
		return false
	}
	arg := self.arg_vec[idx]

	if ret, is_bool := arg.payload.(bool); !is_bool || ret {
		return true
	}

	return false
}

/* get_payload will return the (payload, flag) where the flag
 * represents whether the option was provided at all.  It will
 * always return the same result as if get_flag was called.
 */
get_payload :: proc (self: ^Getargs, arg_name: string) -> (string, bool) {
	idx, ok := self.arg_map[arg_name]
	if !ok {
		fmt.fprintf(os.stderr, "No such argument `%s'\n", arg_name)
		return "", false
	}
	arg := self.arg_vec[idx]

	ret, is_bool := arg.payload.(bool)
	if (is_bool) {
		return "", ret
	}

	return arg.payload.(string), true
}

