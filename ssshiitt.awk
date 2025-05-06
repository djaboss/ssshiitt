#!/usr/bin/env -S awk -f
function showhelp( ) {
 print "ssshiitt.awk version 0.5.2.7_segfault-beta_0;3 BombasticBullcrap"
 print "start ssh connections interactively in the terminal"
 print ""
 print "g[o]: select a host and ssh to it"
 print "      (can also be used to show short host info by aborting)"
 print "c[onfig]: show names of configuration files"
 print "f[ull]: show full config data for a host"
 print "q[uit] (or x): quit program"
 print "help or empty line: show this help"
}

# select a host from list and launch ssh
function gohost(  hn, un, sshc ) {
 hn=selection( iorder, hostname )
 if( hn != "" ) {
  print "preparing for 'ssh " hn "' as " hostinfo[hn]
  printf " other username, empty for same, or . to abort> "
  getline un
  if( un == "." ) return
  if( un == "" ) sshc=sshcmd " " hn
  else sshc=sshcmd " -u " un " " hn
  system( sshc )
  print ""
 }
}

# list selarr (number, text) and get selection
# (optionally displaying additional data from infos array,
# with key from selarr values)
function selection( selarr, infos,  al, ip ) {
 ip=""
# measure array length
 al=0
 for( el in selarr ) al++
 while( ip == "" ) {
# display selection array in descending order
  for( i=al ; i > 0 ; --i ) printf "%4d  %s  %s\n", i, selarr[i], infos[selarr[i]]
  printf "please choose (. to abort)> "
  getline ip
# stay in loop if input does not exist in array
  if( ip != "." && selarr[ip] == "" ) ip=""
 }
 if( ip == "." ) return ""
 else return selarr[ip]
}

function parscfg(  il, oi, host, aun, ahn ) {
# read config and config-order files into arrays config and order
# (global arrays)
 delete config
 delete order
# additional array for selection info
 delete hostinfo
# start with undefined host name and read config file
# (everything until first host will be ignored later on)
 host=""
 while( 1 == getline il <cfg ) {
# remove leading whitespace
  sub(/^[ \t]*/, "", il)
# replace first whitespace separator (one or more SPC or TAB) by a single TAB
  sub(/[ \t]{1,}/, "\t", il)
# "host" line
  if( match( il, /^[hH][oO][sS][tT]\t/ ) == 1 ) {
# delete everything up to TAB
   sub( /.*\t/, "", il )
# what remains is the new host name
   host=il
   if( host in config ) print ":: warning: host " host " already seen, is redefined!"
  }
# if not a "host" line, add it to the information of the current host
 else {
# but only if host is defined and line is not empty or just whitespace
  if( host != "" && match( il, /[^ t]/ ) !=0 ) {
# replace separating TAB by =
   sub( /\t/, "=", il )
# replace home by ~
   sub( home, "~", il )
# if user field
   if( match( il, /^[uU][sS][eE][rR]=/ ) == 1 ) {
    t=il
# get name and save in temp.array
    sub( /.*=/, "", t )
    aun[host]=t
   }
# same for hostname field
   else if( match( il, /^[hH][oO][sS][tT][nN][aA][mM][eE]=/ ) == 1 ) {
    t=il
    sub( /.*=/, "", t )
    ahn[host]=t
    }
# use host if hostname missing
    else ahn[host]=host
   config[host]=config[host] "|" il
   }
  }
 }
 close( cfg )
# combine user and host name info
 for( host in config ) hostinfo[host]=aun[host] "@" ahn[host]
 oi=0
# read file with host lines
 while( 1 == getline il <cfgord ) {
# save existing host name with position oi
# (i.e everything not matching a host will be ignored)
  if( il in config ) order[il]=++oi
 }
 close( cfgord )
# check for all hosts
 for( il in config ) {
# whether already noted in order list
# and append if not
  if( !(il in order) ) order[il]=++oi
  }
# create inverse order list with number as key and host as value
  delete iorder
  for( il in order ) iorder[order[il]]=il
# report number of found hosts (array lengths)
 return oi
}

BEGIN {
home=ENVIRON["HOME"]
sshcmd="ssh"
if( cfg == "" ) cfg=home "/.ssh/config"
if( cfgord == "" ) cfgord=home "/.ssh/.config.order"
print "found " parscfg() " host names"
cmd="help"
while( cmd != "quit" ) {
 if( match( cmd, /^[fF]/ ) ) {
  print config[selection( iorder, hostinfo )]
 }
 if( match( cmd, /^[gG]/ ) ) {
  gohost()
### if you replace "help" by "quit", script will finish afterwards
  cmd="help"
 }
 if( match( cmd, /^[cC]/ ) ) {
  print "config: " cfg
  print " order: " cfgord
 }
 if( cmd == "help" ) showhelp()
 if( match( cmd, /^[qQxX]/ ) ) cmd="quit"
 else {
  printf ">>> "
  getline cmd
  if( cmd == "" ) cmd="help"
  }
 }
}
