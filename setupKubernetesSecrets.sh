#!/usr/bin/env bash

package=$0

function usage {
    echo
    echo "    Usage: Create secrets in kubernetes cluster"
    echo " "
    echo
    echo "    $package [-h|--help] --type=[cloud|local]"
    echo " "
    echo "    options:"
    echo "        -h, --help                         show brief help"
    echo "        --type=[cloud|local]               specify whether this is a 'cloud' or 'local' deployment"
    echo
}

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        usage
                        exit 0
                        ;;
                --type*)
                        export deploymentType=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                *)
                        break
                        ;;
        esac
done

if [[ ${deploymentType} == "" ]]; then
    usage
    exit 1
fi

echo "what is inside the mongo connection place?"
cat $HOME/.secrets/mongoconnectionuri
echo "That was interesting"

kubectl delete secret mongodbkeystore
kubectl create secret generic mongodbkeystore --from-file=cacerts=/etc/ssl/cacerts
kubectl delete secret kafkasecrets
kubectl create secret generic kafkasecrets --from-file=kafkabootstrapservers=$HOME/.secrets/kafkabootstrapservers
kubectl delete secret kafkasasljassusername
kubectl create secret generic kafkasasljassusername --from-file=kafkasasljassusername=$HOME/.secrets/kafkasasljassusername
kubectl delete secret kafkasasljasspassword
kubectl create secret generic kafkasasljasspassword --from-file=kafkasasljasspassword=$HOME/.secrets/kafkasasljasspassword
kubectl delete secret mongoconnectionuri
kubectl create secret generic mongoconnectionuri --from-file=mongoconnectionuri=$HOME/.secrets/mongoconnectionuri
kubectl delete secret timetoteachfacebookid
kubectl create secret generic timetoteachfacebookid --from-file=timetoteachfacebookid=$HOME/.secrets/timetoteachfacebookid
kubectl delete secret timetoteachfacebooksecret
kubectl create secret generic timetoteachfacebooksecret --from-file=timetoteachfacebooksecret=$HOME/.secrets/timetoteachfacebooksecret
kubectl delete secret timetoteachemailpassword
kubectl create secret generic timetoteachemailpassword --from-file=timetoteachemailpassword=$HOME/.secrets/timetoteachemailpassword
