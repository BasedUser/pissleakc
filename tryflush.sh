count=27
curid=1
cat "$1" | while IFS= read -r oline; do
    if [[ "$(((($curid - 1) % 3) + 1))" == "1" ]]; then sleep 0.2s; fi
    echo "PRIVMSG #hamradio :$oline" > $2_$curid
    curid=$(( (${curid} % ${count}) + 1))
    sleep 0.08s; # i edit this before sending anything
done
