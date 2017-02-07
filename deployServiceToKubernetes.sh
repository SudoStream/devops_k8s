#!/usr/bin/env bash
package=$0

function usage {
    echo
    echo "    Usage: Deploy a service to kubernetes cluster"
    echo " "
    echo
    echo "    $package [-h|--help] --service=[scriptwriter|actress] --type=[cloud|local]"
    echo " "
    echo "    options:"
    echo "        -h, --help                         show brief help"
    echo "        --service=[scriptwriter|actress]   specify the service to deploy"
    echo "        --type=[cloud|local]               specify whether this is a 'cloud' or 'local' deployment"
    echo
}

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        usage
                        exit 0
                        ;;
                --service*)
                        export serviceToDeploy=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        if [[ ${serviceToDeploy} != "scriptwriter" && ${serviceToDeploy} != "actress" ]]; then
                            echo "ERROR: Service to deploy must be 'scriptwriter' or 'actress'"
                            exit 1
                        fi
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

if [[ ${serviceToDeploy} == "" || ${deploymentType} == "" ]]; then
    usage
    exit 1
fi

oldNum=`cat dev/kubernetes-${serviceToDeploy}-deployment.yaml | grep bump | cut -d "-" -f2`
newNum=`expr $oldNum + 1`
sed -i "s/bump-$oldNum/bump-$newNum/g" dev/kubernetes-${serviceToDeploy}-deployment.yaml

if [[ ${deploymentType} == "local" ]]; then
    accessToken=`gcloud auth print-access-token`
    kubectl delete secret myregistrykey
    kubectl create secret docker-registry myregistrykey --docker-server=https://eu.gcr.io \
                    --docker-username=oauth2accesstoken \
                    --docker-password=${accessToken} --docker-email=andy@sudostream.io
elif [[ ${deploymentType} == "cloud" ]]; then
    gcloud container clusters get-credentials api-event-horizon-cluster

    git add dev/kubernetes-${serviceToDeploy}-deployment.yaml
    git commit -m "bump"
    git push -u origin master
else
    echo "ERROR: must specify 'local' or 'cloud' run"
    exit 1
fi

kubectl delete --ignore-not-found secret ${serviceToDeploy}-tls
kubectl create secret generic ${serviceToDeploy}-tls --from-file $HOME/.ssh/certs
kubectl delete --ignore-not-found configmap nginx-${serviceToDeploy}-dev-proxf-conf
kubectl create configmap nginx-${serviceToDeploy}-dev-proxf-conf --from-file ./dev/nginx-${serviceToDeploy}.conf
kubectl apply -f ./dev/kubernetes-${serviceToDeploy}-service.yaml --record
kubectl apply -f ./dev/kubernetes-${serviceToDeploy}-deployment.yaml --record
