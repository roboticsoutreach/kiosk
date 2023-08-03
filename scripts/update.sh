#!/bin/bash -e
# Run the kiosk-update.service on the given pi or all pis
# Usage: update.sh  [<pi-name>|[--remote] all]
script_dir="$(dirname -- "$( readlink -f -- "$0")")"

if [ $# -ne 1 ]; then
    echo "Usage: $0 [<pi-name>|all]"
    exit 1
fi

$script_dir/validate || exit 1

remote=""
if [ "$1" == "--remote" ]; then
    shift
    remote="--remote"
fi

if [ "$1" == "all" ]; then
    $script_dir/run-cmd $remote "sudo systemctl start kiosk-update.service"
else
    $script_dir/kiosk-ssh "$1" "sudo systemctl start kiosk-update.service"
fi
