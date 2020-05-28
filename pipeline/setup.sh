#
# OpenShift Pipelines setup
#
oc apply -f 00_roks_setup/02_roks_pipeline_subscription.yaml
while [ ! "$(oc get ClusterServiceVersion openshift-pipelines-operator.v1.0.1 -o template --template={{.status.phase}})" == "Succeeded" ]
do 
    echo "Waiting for pipeline operator"
done

oc apply -f 00_roks_setup/01_buidah-task-patch.yaml


#
# Pipeline setup
#
oc new-project cp4a-builds

oc create secret generic git-pat-kabanero-website --from-literal=github_pat=${GITHUB_PAT}
oc create secret generic ibmcloud-api-key-kabanero-website --from-literal=ibmcloud_api_key=${IBMCLOUD_API_KEY}
oc create configmap env-app-prefix --from-literal=environment=production

oc apply -f 01_pipeline/01_run_script_task.yaml
oc apply -f 01_pipeline/02_publish_cf_task.yaml
oc apply -f 01_pipeline/03_resources.yaml
oc apply -f 01_pipeline/04_pipeline.yaml

#
# Pipeline run
#
oc delete -f 02_pipelinerun/01_build_deploy_kabanero_website_pipelinerun.yaml --ignore-not-found=true
oc apply -f 02_pipelinerun/01_build_deploy_kabanero_website_pipelinerun.yaml

# Follow pipeline run
tkn pipelinerun logs build-and-deploy-kabanero-website-pipelinerun -f

# Start pipeline run using tkn CLI
# tkn pipeline start build-and-deploy-kabanero-website \
# -r git-repo=kabanero-website-repo \
# -r target-image=kabanero-website-image \
# -p app_name_prefix=staging \
# -p ibm_cloud_organization="dnastaci@us.ibm.com" \
# -p ibm_cloud_space=dev \
# -p ibm_cloud_api="https://cloud.ibm.com" \
# -p ibm_cloud_api_key_secret=ibmcloud-api-key-kabanero-website  \
# -p docs_git_url="https://github.com/kabanero-io/docs.git" \
# -p guides_git_url="https://github.com/nastacio/guides.git" \
# -p github_token_secret=git-pat-kabanero-website \
# --showlog

# For debugging a task
# tkn task start publish-cf -i image=api-image -i source=api-repo --showlog
# tkn task start run-script -i image=api-image -i source=api-repo --showlog
