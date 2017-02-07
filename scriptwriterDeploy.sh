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

    #bump
    oldNum=`cat dev/kubernetes-scriptwriter-deployment.yaml | grep bump | cut -d "-" -f2`
    newNum=`expr $oldNum + 1`
    sed -i "s/bump-$oldNum/bump-$newNum/g" dev/kubernetes-scriptwriter-deployment.yaml

    # push bump to git
    git add dev/kubernetes-scriptwriter-deployment.yaml
    git commit -m "bump"
    git push -u origin master
else
    echo "ERROR: must specify 'local' or 'cloud' run"
    exit 1
fi

kubectl delete --ignore-not-found secret scriptwriter-tls
kubectl create secret generic scriptwriter-tls --from-file $HOME/.ssh/certs
kubectl delete --ignore-not-found configmap nginx-scriptwriter-dev-proxf-conf
kubectl create configmap nginx-scriptwriter-dev-proxf-conf --from-file ./dev/nginx-scriptwriter.conf
kubectl apply -f ./dev/kubernetes-scriptwriter-service.yaml --record
kubectl apply -f ./dev/kubernetes-scriptwriter-deployment.yaml --record
