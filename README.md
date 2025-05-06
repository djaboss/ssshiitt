# ssshiitt

**start ssh connections interactively in the terminal**

## `ssshiitt.awk`

*POSIX awk version of a terminal interactive selection script for ssh config*

Most of it should be self-explanatory; in addition, there is also a short
help given when the script is launched.

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
