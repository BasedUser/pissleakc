#!/bin/bash

# config

debug=0
cname="pissleakc"
count=27

#### Boilerplate

fcleanup() { # kill everything for real (i don't think it actually works though so be advised)
  kill $( jobs -p ) 2>/dev/null;
  rm /tmp/$$_*;
  echo "CLEANED ALL JOBS UP"
}

cleanup() { # kill everything
  kill $( jobs -p ) 2>/dev/null;
  rm /tmp/$$_$1;
  echo "CLEANED $1 UP"
}

secho() {
    local yellow=$(echo -ne "\e[33;1m")
    local yellowN=$(echo -ne "\e[37;22m")
    if [[ "$debug" == 0 ]]; then
      echo "$@" > /tmp/$$_$id
    fi
    echo "${yellow}$@${yellowN}"
}

hello() {
    echo "USER pissleakc pissleakc pissleakc :pissleakc printer v1.0"
    echo "NICK ${cname}$(printf \"%02d\" $1)"
    sleep 0.5s;
}

scase()
{ # scase(inp, pos, cmd)
    #local stdin=$(cat)
    local tok=$(echo "$line" | cut -d " " -f "$2")
    if [[ "$1" == "$tok" ]]; then
        #echo "\"$tok\" == \"$1\" passed! running cmd..."
        #echo "$1: echo \"$line\" | $3"
        echo "$line" | $3
        return $?
    fi
    return 0
}

#### Command Parsers

nothingf() { # ignore command
    return 0;
}

nothingt() { # ignore command
    return 1;
}

pong1() { # link-local PINGs
    secho "PONG $(cat | cut -d " " -f 2)"
    return 1;
}

mecho() {
    local curid=1
    cat "$1" | while read -r oline; do
        echo "PRIVMSG #hamradio :$oline" > $$_$curid
        curid=$(( (${curid} % ${count}) + 1))
        sleep 0.4s;
    done
}

privmsg() { # don't actually rely on this function, use tryflush.sh instead (its more configurable)
    if [[ ("$id" == 1) ]]; then
        local stdin=$(cat)
        local src=$(echo -n "$stdin" | cut -d " " -f 1 | cut -d ":" -f 2)
        local dst=$(echo -n "$stdin" | cut -d " " -f 3)
        local msg=${stdin#:*:}
        if [[ ("$dst" == "#hamradio") || ("$src" == "router!router@pissnet/staff/router") ]]; then
            if echo "$msg" | sed -ne 's/^!cat //; t; q 1'; then
                mecho $(echo "$msg" | cut -d " " -f 2) &
                return 1
            fi
        fi
    fi
    return 0
}

loggedon() {
    secho "JOIN #hamradio"
}

#### The MEAT

parser() {
    line=$(echo $1 | cut -d $(echo -ne "\r") -f 1)
    #scase "EOS" 2 nothingt; if [[ $? != 0 ]]; then return 1; fi # TODO speedup synch parsing
    # level 1 (cmd) commands
    scase "PING" 1 pong1; if [[ $? != 0 ]]; then return 1; fi
    # level 2 (:src cmd :payload) commands
    scase "001" 2 loggedon; if [[ $? != 0 ]]; then return 1; fi
    scase "PRIVMSG" 2 privmsg; if [[ $? != 0 ]]; then return 1; fi
    return 0
}

#uncomment if debug=1
#test
#exit

interr() {
  cleanup $id
  echo -e "\nInterrupt caught for $id"
  exit
}

trap fcleanup SIGINT

runner() {
  local id=$1; # do i need to explain this
  id=$id trap interr SIGINT SIGTERM
  botpref=$(echo -ne "\e[33mbot${id}: ") # sanitize stdout - terminals are going to die
  mkfifo /tmp/$$_$id # gotta have something to connect to
  sleep 3652425d > /tmp/$$_$id & # for some wild fucking reason this has to be done for the pipe to not die?? have fun for the next 10000y
  local ip=$(python -c "print(('baseduser.eu.org', 'irc.freenode.ceo', 'nsa.packetscanner.net')[${id}%3],end='')")
  ((sleep 0.5s; hello $id; cat /tmp/$$_$id) & sleep 3650000d) | openssl s_client -quiet -no_ign_eof -connect $ip:6697 | while read -t 120 -r line; do
    out=$(parser "$line")
    handled=$?
    prefix=""
    suffix=""
    if [[ $handled == 1 ]]; then
      prefix=$(echo -ne "\e[32m") # green
      suffix=$(echo -ne "\e[37m")
    else
      prefix=$(echo -ne "\e[31m") # red
      suffix=$(echo -ne "\e[37m")
    fi
    echo "${botpref}${prefix}${line}${suffix}";
    if [[ $out != "" ]]; then
      echo "${botpref}${out}";
    fi
    #echo "$line"
  done
  cleanup $id
}

#### Invocation

for i in $(seq "$count"); do runner $i & sleep 3s; done
echo "EVERYTHING STARTED."
cat > /dev/null
fcleanup # remove our hanging services so we don't die
# if it still doesn't die, `killall sleep`