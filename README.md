A flexible Odin package to parse command line arguments.

## Usage

Arguments are added via the `add_arg` function which looks like this:

```odin
add_arg :: proc (self: ^Getargs,
                 short_name: string = "",
		 long_name: string = "",
		 option: Optarg_Option = .None) {
```

If the `short_name` argument is ever longer than one character, short (single-dash)
options, then single-dash options will have the same behavior as long (double-dash)
options.  Otherwise, the default behavior is like the GNU style.

### GNU style:

```odin
argparser := getargs.make_getargs()
getargs.add_arg(&argparser, "d", "dynamic", getargs.Optarg_Option.None)
getargs.add_arg(&argparser, "f", "first", getargs.Optarg_Option.None)
getargs.add_arg(&argparser, "s", "second", getargs.Optarg_Option.None)
getargs.add_arg(&argparser, "n", "number", getargs.Optarg_Option.Required)
getargs.add_arg(&argparser, "S", "special", getargs.Optarg_Option.Optional)
```

Since all of the `short_name` parmeters are a single character, this will use a GNU-like
behavior.  The following examples are acceptable:

```sh
# single flag options with no arguments can be chained together...
program -fs          # equivalent to program -f -s
program -fn2         # equivalent to program -f -n 2

# long options can optionally use '=' to delimit the argument...
program --special=hi # equivalent to program -S hi
program --special hi # equivalent to program -S hi
```


### single-dash long options

```odin
argparser := getargs.make_getargs()
getargs.add_arg(&argparser, "d", "", getargs.Optarg_Option.None)
getargs.add_arg(&argparser, "f", "", getargs.Optarg_Option.None)
getargs.add_arg(&argparser, "second", "", getargs.Optarg_Option.None)
getargs.add_arg(&argparser, "number", "", getargs.Optarg_Option.Required)
getargs.add_arg(&argparser, "special", "", getargs.Optarg_Option.Optional)
```

Given the above, there are long names in the `short_name` field. This will
treat single-dash options the same as long options.

```sh
# Can no longer chain together single flags
program -fs     # will fail because it cannot find option 'fs'
program -n2     # will fail because it cannot find option 'n2'

# just like the double-dash long options...
program -special=hi
program -special hi
```
