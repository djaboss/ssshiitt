#!/usr/bin/env -S awk -f
function showhelp( ) {
 print "ssshiitt.awk version 0.5.2.9_segfault-gamma_7;4 HolyHemorrage"
 print "handle ssh connections interactively in the terminal"
 print ""
 print "g[o] or empty input: select a host and ssh to it"
 print "      (can also be used to show short host info by aborting)"
 print "c[onfig]: show names of configuration files and config variables"
 print "f[ilter]: enter regexp to filter for hostnames or configs"
 print "s[how]: show full config data for a host"
 print "a[ll]: show full config data for all hosts"
 print "q[uit] or .: quit program"
 print "help or ?: show this help"
}

function finish( ) {
 saveorder()
 print ""
 print ":: script aborted ::"
 exit
}

# select a host from list and launch ssh
function gohost(  hn, un, sshc ) {
# get hostname
 hn=selection( iorder, hostname, supplist )
# empty selection: abort
 if( hn != "" ) {
  print "preparing for 'ssh " hn "' as " hostinfo[hn]
  printf " other username, empty for same, or . to abort> "
  if( 1 != getline un ) finish()
  if( un != "." ) {
# default: ssh hostname
   if( un == "" ) sshc=sshcmd " " hn
# else set explicit username
   else sshc=sshcmdu " " un " " hn
   print "launching command " sshc
   system( sshc )
   system( "date -u" )
  }
  print ""
# update config order
  saveorder( hn )
# re-read configuration to update order
  entries=parscfg()
 }
}

# list selarr (number, text) and get selection
# (optionally displaying additional data from infos array,
# with key from selarr values, and suppressing keys from hide)
function selection( selarr, infos, hide,  al, ip ) {
 ip=""
# measure array length
 al=0
 for( el in selarr ) al++
 while( ip == "" ) {
# display selection array in descending order
# but skip entries from hide and empty ones
  for( i=al ; i > 0 ; --i ) if( !(selarr[i] in hide) &&
   selarr[i] != "" )
   printf "%4d  %s  %s\n", i, selarr[i], infos[selarr[i]]
  printf "please choose (. to abort)> "
  if( 1 != getline ip ) finish()
# stay in loop if input does not exist in array
  if( ip != "." && selarr[ip] == "" ) ip=""
 }
 if( ip == "." ) return ""
 else return selarr[ip]
}

function parscfg(  il, oi, host, aun, ahn, kv ) {
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
# if the line can be split by TAB or SPC, assume key/value pair
# (NB: cannot handle TAB/SPC *in* value!)
  if( split( il, kv, /[\t ]/ ) > 1 ) cfgvar[kv[1]]=kv[2]
# else save existing host name with position oi
# (i.e everything not matching a host will be ignored)
  else if( il in config ) order[il]=++oi
   else print ": unknown config hostname", il
 }
 close( cfgord )
# check for all hosts whether noted in order list and append if not
 for( il in config ) if( !(il in order) ) order[il]=++oi
# generate inverse order list
 for( hn in order ) iorder[order[hn]]=hn
 makehide()
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
# save cfgvariables as key/value pairs
 for( kk in cfgvar ) print kk, cfgvar[kk] >> cfgord
 close( cfgord )
}

# make list of hidden entries
function makehide(  filtr, hn ) {
 fltr=cfgvar["hostfilter"]
# if no filter is defined, use wildcard . (i.e none)
 if( fltr == "" ) fltr="."
 print ": filtering for /" fltr "/ :"
# clear global list of suppressed host numbers
 delete supplist
# only add to list if neither hostname nor config match
 for( hn in order ) if( match( hn, fltr ) == 0 &&
  match( config[hn], fltr ) == 0 ) supplist[hn]=order[hn]
 saveorder()
}

BEGIN {
home=ENVIRON["HOME"]
sshcmd="ssh"
sshcmdu="ssh -l"
if( cfg == "" ) cfg=home "/.ssh/config"
if( cfgord == "" ) cfgord=home "/.ssh/.config.order"
entries=parscfg()
print "found " entries " host names"
# by setting cmd in the script's argument, you can choose how to start
if( cmd == "" ) cmd="go"
while( cmd != "quit" ) {
 if( match( cmd, /^[sS]/ ) ) {
  print config[selection( iorder, hostinfo, supplist )]
 }
 if( match( cmd, /^[aA]/ ) ) for( hn in config ) print "- " hn " " config[hn]
 if( match( cmd, /^[gG]/ ) ) {
  gohost()
### if you replace "help" by "quit", script will finish afterwards
  cmd="help"
 }
 if( match( cmd, /^[fF]/ ) ) {
  fltr=cfgvar["hostfilter"]
  if( fltr == "" ) fltr="."
  print "current filter=/" fltr "/"
  printf "enter new (without //) or . to clear or empty to keep> "
  getline fltr
  if( fltr != "" ) cfgvar["hostfilter"]=fltr
 makehide()
 }
 if( match( cmd, /^[cC]/ ) ) {
  print "config: " cfg
  print " order: " cfgord
  for( k in cfgvar ) print " var " k "=" cfgvar[k]
 }
 if( cmd == "help" || cmd == "?" ) showhelp()
 if( match( cmd, /^[qQ.]/ ) ) cmd="quit"
 else {
  printf ">>> "
  if( 1 != getline cmd ) finish()
  if( cmd == "" ) cmd="go"
  }
 }
}
