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

curr_dir=`pwd`

svc_dir=`mktemp -d` && cd ${svc_dir}
git clone git@github.com:SudoStream/svc_${serviceToDeploy}.git
cd svc_${serviceToDeploy}

build_version_in_quotes=`cat build.sbt  | grep "version :=" | awk '{print $3}'  `
build_version_stripped=`echo ${build_version_in_quotes:1:-1} `

cd ${curr_dir}
rm -rf ${svc_dir}

# bump the label number
oldNum=`cat dev/kubernetes-${serviceToDeploy}-deployment.yaml | grep bump | cut -d "-" -f2`
newNum=`expr $oldNum + 1`
sed -i "s/bump-$oldNum/bump-$newNum/g" dev/kubernetes-${serviceToDeploy}-deployment.yaml

################## update the image version of service to latest ####################################
#image_version="eu.gcr.io\/time-to-teach-zone\/${serviceToDeploy}:${build_version_stripped}"
#sed_command="/.*image.*${serviceToDeploy}.*/  s/image:.*$/image: ${image_version}/g"
#sed -i "${sed_command}" dev/kubernetes-${serviceToDeploy}-deployment.yaml
#####################################################################################################

if [[ ${deploymentType} == "local" ]]; then
    accessToken=`gcloud auth print-access-token`
    kubectl delete secret myregistrykey
    kubectl create secret docker-registry myregistrykey --docker-server=https://eu.gcr.io \
                    --docker-username=oauth2accesstoken \
                    --docker-password=${accessToken} --docker-email=andy@timetoteach.zone
elif [[ ${deploymentType} == "cloud" ]]; then
    gcloud container clusters get-credentials timetoteach-dev-cluster

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
if [[ ${deploymentType} == "local" ]]; then
    kubectl delete deployment ${serviceToDeploy}
    kubectl apply -f ./local/kubernetes-${serviceToDeploy}-service.yaml --record
else
    kubectl apply -f ./dev/kubernetes-${serviceToDeploy}-service.yaml --record
fi

if [[ ${deploymentType} == "local" ]]; then
    kubectl apply -f ./local/kubernetes-${serviceToDeploy}-deployment.yaml --record
else
    kubectl apply -f ./dev/kubernetes-${serviceToDeploy}-deployment.yaml --record
fi


