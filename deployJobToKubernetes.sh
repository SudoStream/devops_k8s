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
    echo "    $package [-h|--help] --service=[[JOB_NAME - see below]] --type=[cloud|local]"
    echo " "
    echo "    options:"
    echo "        -h, --help                         show brief help"
    echo "        --service=[esandospopulator]   specify the service to deploy"
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
                        if [[  ${serviceToDeploy} != "esandospopulator" && \
                               ${serviceToDeploy} != "test-populator"
                         ]]; then
                            echo "ERROR: Job to deploy must be one of 'esandospopulator'"
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

if [[ "${deploymentType}" == "local" ]]; then
    K8S_ENV_TYPE="local"
elif [[ "${deploymentType}" == "cloud" ]]; then
    K8S_ENV_TYPE="dev"
fi

echo "K8S_ENV_TYPE = ${K8S_ENV_TYPE}"

oldNum=`cat ${K8S_ENV_TYPE}/kubernetes-${serviceToDeploy}-job.yaml | grep bump | cut -d "-" -f2`
newNum=`expr $oldNum + 1`
sed -i "s/bump-$oldNum/bump-$newNum/g" ${K8S_ENV_TYPE}/kubernetes-${serviceToDeploy}-job.yaml

if [[ "${deploymentType}" == "local" ]]; then
    echo "-----------------------------------'local'"
elif [[ "${deploymentType}" == "cloud" ]]; then
    echo "-----------------------------------'cloud'"
    gcloud container clusters get-credentials timetoteach-dev-cluster

    git add ${K8S_ENV_TYPE}/kubernetes-${serviceToDeploy}-job.yaml
    git commit -m "bump"
    git push -u origin master
else
    echo "ERROR: must specify 'local' or 'cloud' run"
    exit 1
fi

kubectl delete job ${serviceToDeploy}
kubectl apply -f ./${K8S_ENV_TYPE}/kubernetes-${serviceToDeploy}-job.yaml --record
echo "--- Deployed ${serviceToDeploy} ---"