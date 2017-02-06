#!/usr/bin/env bash
deploymentType=$1

if [[ ${deploymentType} == "local" ]]; then
    accessToken=`gcloud auth print-access-token`
    kubectl delete secret myregistrykey
    kubectl create secret docker-registry myregistrykey --docker-server=https://eu.gcr.io \
                    --docker-username=oauth2accesstoken \
                    --docker-password=${accessToken} --docker-email=andy@sudostream.io
elif [[ ${deploymentType} == "cloud" ]]; then
    gcloud container clusters get-credentials api-event-horizon-cluster

    oldNum=`cat dev/kubernetes-actress-deployment.yaml | grep bump | cut -d "-" -f2`
    newNum=`expr $oldNum + 1`
    sed -i "s/bump-$oldNum/bump-$newNum/g" dev/kubernetes-actress-deployment.yaml

    git add dev/kubernetes-actress-deployment.yaml
    git commit -m "bump"
    git push -u origin master
else
    echo "ERROR: must specify 'local' or 'cloud' run"
    exit 1
fi

kubectl delete secret scriptwriter-tls
kubectl create secret generic scriptwriter-tls --from-file $HOME/.ssh/certs
kubectl delete configmap nginx-actress-dev-proxf-conf
kubectl create configmap nginx-actress-dev-proxf-conf --from-file ./dev/nginx-actress.conf
kubectl apply -f ./dev/kubernetes-actress-service.yaml --record
kubectl apply -f ./dev/kubernetes-actress-deployment.yaml --record
