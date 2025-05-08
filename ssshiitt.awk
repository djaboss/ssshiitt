#!/usr/bin/env -S awk -f
function showhelp( ) {
 print "ssshiitt.awk version 0.5.2.7_segfault-beta_0;6 BombasticBullcrap"
 print "start ssh connections interactively in the terminal"
 print ""
 print "g[o]: select a host and ssh to it"
 print "      (can also be used to show short host info by aborting)"
 print "c[onfig]: show names of configuration files"
 print "s[how]: show full config data for a host"
 print "a[ll]: show full config data for all hosts"
 print "q[uit] or .: quit program"
 print "help or empty line: show this help"
}

function finish( ) {
 print ""
 print ":: script aborted ::"
 exit
}

# select a host from list and launch ssh
function gohost(  hn, un, sshc ) {
# get hostname
 hn=selection( iorder, hostname )
# empty selection: abort
 if( hn != "" ) {
  print "preparing for 'ssh " hn "' as " hostinfo[hn]
  printf " other username, empty for same, or . to abort> "
  if( 1 != getline un ) finish()
  if( un == "." ) return
# default: ssh hostname
  if( un == "" ) sshc=sshcmd " " hn
# else set explicit username
  else sshc=sshcmd " -u " un " " hn
  print "launching command " sshc
  system( sshc )
  print ""
# update config order
  saveorder( hn )
# re-read configuration to update order
  entries=parscfg()
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
  if( 1 != getline ip ) finish()
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

# save config order
function saveorder( hn,  on ) {
# last used hostname will be on top of list
 print hn > cfgord
# all others will come after
 for( i=1; i <= entries; ++i ) {
  on=iorder[i]
  if( on != hn ) print on >> cfgord
 }
 close( cfgord )
}

BEGIN {
home=ENVIRON["HOME"]
sshcmd="ssh"
if( cfg == "" ) cfg=home "/.ssh/config"
if( cfgord == "" ) cfgord=home "/.ssh/.config.order"
entries=parscfg()
print "found " entries " host names"
# by setting cmd in the script's argument, you can choose how to start
if( cmd == "" ) cmd="go"
while( cmd != "quit" ) {
 if( match( cmd, /^[sS]/ ) ) {
  print config[selection( iorder, hostinfo )]
 }
 if( match( cmd, /^[aA]/ ) ) for( hn in config ) print "- " hn " " config[hn]
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
 if( match( cmd, /^[qQ.]/ ) ) cmd="quit"
 else {
  printf ">>> "
  if( 1 != getline cmd ) finish()
  if( cmd == "" ) cmd="help"
  }
 }
}
