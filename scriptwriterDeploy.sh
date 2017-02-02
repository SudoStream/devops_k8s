#!/usr/bin/env bash
shouldskip=$1

if [[ ${shouldskip} != "local" ]]; then
    gcloud container clusters get-credentials api-event-horizon-cluster

    #bump
    oldNum=`cat dev/kubernetes-scriptwriter-deployment.yaml | grep bump | cut -d "-" -f2`
    newNum=`expr $oldNum + 1`
    sed -i "s/bump-$oldNum/bump-$newNum/g" dev/kubernetes-scriptwriter-deployment.yaml

    # push bump to git
    git add dev/kubernetes-scriptwriter-deployment.yaml
    git commit -m "bump"
    git push -u origin master
fi

kubectl delete secret scriptwriter-tls
kubectl create secret generic scriptwriter-tls --from-file $HOME/.ssh/certs
kubectl delete configmap nginx-scriptwriter-dev-proxf-conf
kubectl create configmap nginx-scriptwriter-dev-proxf-conf --from-file ./dev/nginx-scriptwriter.conf
kubectl apply -f ./dev/kubernetes-scriptwriter-service.yaml --record
kubectl apply -f ./dev/kubernetes-scriptwriter-deployment.yaml --record
