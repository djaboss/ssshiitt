# ssshiitt

**start ssh connections interactively in the terminal**

## `ssshiitt.awk`

*POSIX awk version of a terminal interactive selection script for ssh config*

The script immediately starts with the "go" command for selecting a host for connecting to, as this is its main purpose.
This can be changed either definitely in the script (search for the line containing 'cmd="go"') or per run by setting the cmd variable on the command line (e.g with a '-v cmd=help' argument).
In any case, the go command can be aborted by entering a dot (.) so that the script returns to the main command loop (REPL).

### Installation and Running

Get it! `:D`

The script is written in POSIX awk and therefore should run with any sane
awk interpreter.

In addition, it uses the "ENV hashbang" functionality, i.e if it is made executable on a Unix/Linux system, it should be possible to launch it by starting it directly as `./ssshiitt.awk` from the shell.

If this fails, it can be run with `awk -P -f ssshiitt.awk` in the shell (actually, the -P option for POSIX compatibility might be omitted on most systems).

### Principle of Operation

The script reads the ssh config file (at `~/.ssh/config` but this can be changed by modifying the script source) and puts its contents in various arrays.
From these arrays, a list of hostnames with preceding numbers is displayed.
By selecting the appropriate number, an ssh connection to the corresponding host can be established.

The host list for selection is ordered by last use: the most recently used host is on position 1, the previous on 2, etc.
This list is saved as `~/.ssh/.config.order` (hardcoded in the script, but of course changeable).
It is displayed in descending order, i.e position 1 is at the bottom of the list, to show the most used hosts close to where the selection is entered.

*Note:* CTRL-D at a prompt closes STDIN and therefore cuts off the script from keyboard control. This is catched, but the script will then print an abort warning and immediately exit, as it becomes uncontrollable.
