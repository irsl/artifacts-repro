#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Usage: $0 runtime-token-str|double-b64-encoded-actions-environment-json-str"
  exit 1
fi

export ACTIONS_RUNTIME_TOKEN="$(echo "$1" | base64 -d 2>/dev/null | base64 -d 2>/dev/null | jq -r .ACTIONS_RUNTIME_TOKEN)"

if [[ -n "$ACTIONS_RUNTIME_TOKEN" ]]; then
  echo "The input is an environment dump"
else
  echo "The input is an ACTIONS_RUNTIME_TOKEN"
  export ACTIONS_RUNTIME_TOKEN="$1"
fi


ACTIONS_RUNTIME_TOKEN_PAYLOAD="$(echo $ACTIONS_RUNTIME_TOKEN|cut -d. -f2| base64 -d 2>/dev/null)"

SCP="$(echo "$ACTIONS_RUNTIME_TOKEN_PAYLOAD" | jq -r .scp)"
for ascp in $SCP; do
  if echo $ascp | grep Actions.Results >/dev/null; then
     export B1="$(echo $ascp | cut -d: -f2)"
     export B2="$(echo $ascp | cut -d: -f3)"
     break
  fi
done

export ACTIONS_RESULTS_URL=https://results-receiver.actions.githubusercontent.com

echo
echo
echo "To create an artifact, run:"
cat <<'EOF'
UPLOAD_URL="$(curl  -v -H "Authorization: Bearer $ACTIONS_RUNTIME_TOKEN" -H "Content-Type: application/json" -d '{ "workflowRunBackendId": "'$B1'", "workflowJobRunBackendId": "'$B2'", "name": "hello1.txt", "version": 4 }' "$ACTIONS_RESULTS_URL/twirp/github.actions.results.api.v1.ArtifactService/CreateArtifact" | jq -r .signed_upload_url)"
EOF
echo

echo "To upload a content, run:"
cat <<'EOF'
curl -X PUT -d "this-is-the-content" -H "Content-Type: application/octet-stream" -H "x-ms-version: 2025-01-05" -H "Accept: application/xml" -H "x-ms-blob-type: BlockBlob" -H "User-Agent: azsdk-js-azure-storage-blob/12.26.0 core-rest-pipeline/1.19.0 Node/22.8.0 OS/(x64-Linux-5.10.102.1-microsoft-standard-WSL2)" -H "x-ms-client-request-id: 36478bd5-cb6a-4ddc-845e-703232ba6ea4"  "$UPLOAD_URL" -v
EOF
echo

echo "To finalize an artifact, run:"
cat <<'EOF'
curl  -v -H "Authorization: Bearer $ACTIONS_RUNTIME_TOKEN" -H "Content-Type: application/json" -d '{ "workflowRunBackendId": "'$B1'", "workflowJobRunBackendId": "'$B2'", "name": "hello1.txt", "size": 8 }' "$ACTIONS_RESULTS_URL/twirp/github.actions.results.api.v1.ArtifactService/FinalizeArtifact"
EOF
echo

