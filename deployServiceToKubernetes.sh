#!/bin/bash
package=$0

# api-antagonist
# amateur-screenwriter
# studio
# genre-romcom-screenwriter


function usage {
    echo
    echo "    Usage: Deploy a service to kubernetes cluster"
    echo " "
    echo
    echo "    $package [-h|--help] --service=[[SERVICE_NAME - see below]] --type=[cloud|local]"
    echo " "
    echo "    options:"
    echo "        -h, --help                         show brief help"
    echo "        --service=[job-esAndOsPopulator|timetoteach-ui-server|es-and-os-reader]   specify the service to deploy"
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
                        echo "Deploying ... ${serviceToDeploy}"
                        if [[   ${serviceToDeploy} != "timetoteach-ui-server" && \
                                ${serviceToDeploy} != "school-reader" && \
                                ${serviceToDeploy} != "school-writer" && \
                                ${serviceToDeploy} != "user-writer" && \
                                ${serviceToDeploy} != "user-reader" && \
                                ${serviceToDeploy} != "classtimetable-writer" && \
                                ${serviceToDeploy} != "classtimetable-reader" && \
                                ${serviceToDeploy} != "es-and-os-reader" ]]; then
                            echo "ERROR: Service Name not known"
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

if [[ ${deploymentType} == "local" ]]; then
    K8S_ENV_TYPE="local"
elif [[ ${deploymentType} == "cloud" ]]; then
    K8S_ENV_TYPE="dev"
fi


# bump the label number
oldNum=`cat ${K8S_ENV_TYPE}/kubernetes-${serviceToDeploy}-deployment.yaml | grep bump | cut -d "-" -f2`
newNum=`expr $oldNum + 1`
sed -i "s/bump-$oldNum/bump-$newNum/g" ${deploymentType}/kubernetes-${serviceToDeploy}-deployment.yaml

if [[ ${deploymentType} == "local" ]]; then
    accessToken=`gcloud auth print-access-token`
    kubectl delete secret myregistrykey
    kubectl create secret docker-registry myregistrykey --docker-server=https://eu.gcr.io \
                    --docker-username=oauth2accesstoken \
                    --docker-password=${accessToken} --docker-email=andy@timetoteach.zone
elif [[ ${deploymentType} == "cloud" ]]; then
    gcloud container clusters get-credentials timetoteach-dev-cluster

    git add ${K8S_ENV_TYPE}/kubernetes-${serviceToDeploy}-deployment.yaml
    git commit -m "bump"
    git push -u origin master
else
    echo "ERROR: must specify 'local' or 'cloud' run"
    exit 1
fi

kubectl delete --ignore-not-found secret ${serviceToDeploy}-tls
kubectl create secret generic ${serviceToDeploy}-tls --from-file $HOME/.ssh/certs
kubectl delete --ignore-not-found configmap nginx-${serviceToDeploy}-dev-proxf-conf
kubectl create configmap nginx-${serviceToDeploy}-dev-proxf-conf --from-file ./${K8S_ENV_TYPE}/nginx-${serviceToDeploy}.conf
kubectl apply -f ./${K8S_ENV_TYPE}/kubernetes-${serviceToDeploy}-service.yaml --record
kubectl apply -f ./${K8S_ENV_TYPE}/kubernetes-${serviceToDeploy}-deployment.yaml --record

