package getargs

import "core:fmt"
import "core:os"

@(private)
Optarg :: union {
	string,
	bool,
}

@(private)
Argument :: struct {
	option:  Optarg_Option,
	payload: Optarg,
}

Getargs :: struct {
	short_map: map[string]int,
	long_map: map[string]int,
	arg_vec: [dynamic]Argument,
	optind: int,
	short_as_long: bool,
}

Optarg_Option :: enum {
	None,
	Required,
	Optional,
}

add_arg :: proc (self: ^Getargs,
                 short_name: string = "",
		 long_name: string = "",
		 option: Optarg_Option = .None) {
	idx := len(self.arg_vec)

	append(&self.arg_vec, Argument{option=option, payload=false})

	if (len(short_name) > 0) {
		self.short_map[short_name] = idx
		if len(short_name) > 1 {
			self.short_as_long = true
		}
	}
	if (len(long_name) > 0) {
		self.long_map[long_name] = idx
	}
}

make_getargs :: proc () -> Getargs {
	return Getargs { 
		short_map=make(map[string]int),
	        long_map=make(map[string]int),
		arg_vec=make([dynamic]Argument),
		optind = 1,
	}
}

init_getargs :: proc (self: ^Getargs) {
	self^ = {
		short_map=make(map[string]int),
	        long_map=make(map[string]int),
		arg_vec=make([dynamic]Argument),
		optind = 1,
	}
}

@(private)
_parse_short_args :: proc(self: ^Getargs, args: []string) -> bool {
	i := 1
	for ; i < len(args[self.optind]); i += 1 {
		idx, ok := self.short_map[args[self.optind][i:i+1]]
		if !ok {
			fmt.fprintf(os.stderr, "unable to find arg `%s'\n", args[self.optind][i:i+1])
			return true
		}
		
		arg := &self.arg_vec[idx]
		
		if (arg.option == .None) {
			arg.payload = true
			continue
		}

		if i+1 < len(args[self.optind]) {
			arg.payload = args[self.optind][i+1:]
			if arg.option == .Optional || len(arg.payload.(string)) > 0 {
				return false
			}
			fmt.fprintf(os.stderr, "`%c' expects an argument\n", args[self.optind][i])
			return true
		}

		if self.optind + 1 >= len(args) || args[self.optind+1][0] == '-' {
			if arg.option == .Optional {
				arg.payload = true
				return false
			}

			fmt.fprintf(os.stderr, "`%c' expects an argument\n", args[self.optind][i])
			return true
		}

		self.optind += 1
		arg.payload = args[self.optind]

		break;
	}
	return false
}

@(private)
_parse_short_as_long :: proc(self: ^Getargs, args: []string) -> bool {
	arg_name : string
	has_optarg : bool

	i := 1
	for ; i < len(args[self.optind]); i += 1 {
		if args[self.optind][i] == '=' {
			arg_name = args[self.optind][1:i]
			has_optarg = true
			break;
		}
	}

	if !has_optarg {
		arg_name = args[self.optind][1:]
	}

	idx, ok := self.short_map[arg_name]
	if !ok {
		fmt.fprintf(os.stderr, "unable to find arg `%s'\n", arg_name)
		return true
	}

	//arg := self.arg_vec[idx]
	arg := &self.arg_vec[idx]
	if has_optarg && arg.option == .None {
		fmt.fprintf(os.stderr, "`%s' does not expect an argument\n", arg_name)
		return true
	}

	if arg.option == .None {
		arg.payload = true
		return false
	}

	if has_optarg {
		arg.payload = args[self.optind][i+1:]
		return false
	}

	if self.optind + 1 >= len(args) || args[self.optind+1][0] == '-' {
		if arg.option == .Optional {
			arg.payload = true
			return false
		}

		fmt.fprintf(os.stderr, "`%s' expects an argument\n", arg_name)
		return true
	}

	self.optind += 1
	arg.payload = args[self.optind]

	return false
}

@(private)
_parse_long_arg :: proc(self: ^Getargs, args: []string) -> bool {
	arg_name : string
	has_optarg : bool

	i := 1
	for ; i < len(args[self.optind]); i += 1 {
		if args[self.optind][i] == '=' {
			arg_name = args[self.optind][2:i]
			has_optarg = true
			break;
		}
	}

	if !has_optarg {
		arg_name = args[self.optind][2:]
	}

	idx, ok := self.long_map[arg_name]
	if !ok {
		fmt.fprintf(os.stderr, "unable to find arg `%s'\n", arg_name)
		return true
	}

	arg := &self.arg_vec[idx]
	if has_optarg && arg.option == .None {
		fmt.fprintf(os.stderr, "`%s' does not expect an argument\n", arg_name)
		return true
	}

	if arg.option == .None {
		arg.payload = true
		return false
	}

	if has_optarg {
		arg.payload = args[self.optind][i+1:]
		return false
	}

	if self.optind + 1 >= len(args) || args[self.optind+1][0] == '-' {
		if arg.option == .Optional {
			arg.payload = true
			return false
		}

		fmt.fprintf(os.stderr, "`%s' expects an argument\n", arg_name)
		return true
	}

	self.optind += 1
	arg.payload = args[self.optind]

	return false
}

read_args :: proc (self: ^Getargs, args : []string) -> bool {
	for ; self.optind < len(args); self.optind += 1 {
		/* Check if arg at all */
		if args[self.optind][0] != '-' {
			return false
		}

		/* Check if long arg */
		if len(args[self.optind]) > 2 && args[self.optind][1] == '-' {
			if _parse_long_arg(self, args) {
				return true
			}
			continue
		}

		if self.short_as_long {
			if _parse_short_as_long(self, args) {
				return true
			}
		} else {
			if _parse_short_args(self, args) {
				return true
			}
		}
	}
	return false
}

get_flag :: proc (self: ^Getargs, arg_name: string) -> bool {
	idx, ok := self.short_map[arg_name]
	if !ok {
		idx, ok = self.long_map[arg_name]
		if !ok {
			fmt.fprintf(os.stderr, "No such argument `%s'\n", arg_name)
			return false
		}
	}

	arg := self.arg_vec[idx]

	if ret, is_bool := arg.payload.(bool); !is_bool || ret {
		return true
	}

	return false
}

get_payload :: proc (self: ^Getargs, arg_name: string) -> (string, bool) {
	idx, ok := self.short_map[arg_name]
	if !ok {
		idx, ok = self.long_map[arg_name]
		if !ok {
			fmt.fprintf(os.stderr, "No such argument `%s'\n", arg_name)
			return "", false
		}
	}

	arg := self.arg_vec[idx]

	ret, is_bool := arg.payload.(bool)
	if (is_bool) {
		return "", ret
	}

	return arg.payload.(string), true
}

