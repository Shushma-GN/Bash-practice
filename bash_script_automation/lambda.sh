#!/bin/bash
request_type="$1"
# Set lambda_workspace_version="v4.x" if needed
if [ ! -z ${BAPP_ID} ]; then
BAG="ee"
[ ! -z $SID ] && BID=$(echo $SID | sed 's/S/BID/g') || BID=""
else
echo " BAPP_ID is empty. Exiting.. "
exit 1
fi
BAPP_SHORT="B$(echo $BAPP_ID | cut -c 5-)"
if [ "$ENVIRONMENT" == "latest" ]; then
ENV_SHORT="lst"
elif [ "$ENVIRONMENT" == "stage" ]; then
ENV_SHORT="stg"
elif [ "$ENVIRONMENT" == "load" ]; then
ENV_SHORT="lod"
fi
if [ "$SITE" == "wdw" ]; then
REGION="us-east-1" && REGION_SHORT="use1" && NAME_NODE_ID="2491"
if [ "$ENVIRONMENT" == "latest" ]; then
ACCOUNT="wdpr-ee-dev" && ACCOUNT_NO=520778242457
elif [ "$ENVIRONMENT" == "stage" ] || [ "$ENVIRONMENT" == "load" ]; then
ACCOUNT="wdpr-ee-dev" && ACCOUNT_NO=520778242457
fi
elif [ "$SITE" == "dlr" ]; then
REGION="us-west-2" && REGION_SHORT="usw2" && NAME_NODE_ID="2492"
if [ "$ENVIRONMENT" == "latest" ]; then
ACCOUNT="wdpr-ee-dev" && ACCOUNT_NO="520778242457"
elif [ "$ENVIRONMENT" == "stage" ] || [ "$ENVIRONMENT" == "load" ]; then
ACCOUNT="wdpr-ee-dev" && ACCOUNT_NO="520778242457"
fi
fi
if [ "$request_type" == "check_tfvars_exists" ]; then
export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
$(aws sts assume-role \
--role-arn arn:aws:iam::$ACCOUNT_NO:role/WDPR-CICD-cross-pradeep \
--role-session-name harnessaws \
--query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
--output text))
tfvars_found="false"
function_found="false"
if [ -z $SID ]; then
cwl_log_grp_prefix1="/aws/lambda/${SITE}-${BAG}-${BAPP_SHORT}-${REGION_SHORT}-${ENV_SHORT}-${APP}"
cwl_log_grp_prefix2="/aws/lambda/wdpr-${BAG}-${BAPP_SHORT}-${REGION_SHORT}-${ENV_SHORT}-${APP}"
else
cwl_log_grp_prefix1="/aws/lambda/${SITE}-${BAG}-${SID}-${REGION_SHORT}-${ENV_SHORT}-${APP}"
cwl_log_grp_prefix2="/aws/lambda/wdpr-${BAG}-${SID}-${REGION_SHORT}-${ENV_SHORT}-${APP}"

fi
for cwl_log_grp_prefix in $cwl_log_grp_prefix1 $cwl_log_grp_prefix2; do
echo $cwl_log_grp_prefix
[ "${tfvars_found}" == "true" ] && echo "breaking" && break
log_grp_resp=$(aws logs describe-log-groups --log-group-name-prefix $cwl_log_grp_prefix --region ${REGION} --query
"logGroups[*].arn")
echo ${log_grp_resp}
log_arn_list=$(echo $log_grp_resp | sed -e 's/[\[]//g' -e 's/[]]//g' -e 's/,/ /g')
echo ${log_arn_list}
cd ${local_repo}
ls
for arn in $log_arn_list; do
[ "${function_found}" == "true" ] && echo "breaking" && break
arn_modified=$(echo $arn | sed -e 's/:\*//g' -e "s/\"//g")
echo $arn_modified
response=$(aws logs list-tags-for-resource --resource-arn $arn_modified --region $REGION --query "tags.tf_state")
echo $response
tfvars_file_name=$(echo $response | awk -F '/' '{print $5}')
echo "TFVARS:$tfvars_file_name"
if [ ! -z $tfvars_file_name ]; then
find ${LAMBDA_WORKSPACE_FOLDER} -name ${tfvars_file_name}.tfvars
tfvars_with_path=$(find ${LAMBDA_WORKSPACE_FOLDER} -name ${tfvars_file_name}.tfvars 2>/dev/null)
tfvars_without_extn=$(echo $tfvars_with_path | cut -d '.' -f1)
echo "TFVARS PATH:$tfvars_with_path"
if [ "$tfvars_with_path" == "${LAMBDA_WORKSPACE_FOLDER}/${tfvars_file_name}.tfvars" ]; then
tfvars_found="true"
fi
fi
cwl_log_group=$(echo $arn | cut -d ':' -f7)
echo $cwl_log_group":::"${cwl_log_grp_prefix}-${FUNCTION_NAME}
if [ "$cwl_log_group" == "${cwl_log_grp_prefix}-${FUNCTION_NAME}" ]; then
echo "Lambda exists..."
function_found="true"
fi
done
done
if [ "$tfvars_found" == "true" ]; then
if [ "$function_found" == "true" ]; then
echo "FUNCTION_FOUND|TFVARS_FOUND|${tfvars_without_extn}"
else
echo "FUNCTION_NOTFOUND|TFVARS_FOUND|${tfvars_without_extn}"
fi
else
[ -z $SID ] && tfvars_with_path="${SITE}-${APP}-${BAPP_SHORT}-${REGION_SHORT}-${ENV_SHORT}-harness" ||
tfvars_with_path="${SITE}-${APP}-${SID}-${REGION_SHORT}-${ENV_SHORT}-harness"
echo "FUNCTION_NOTFOUND|TFVARS_NOTFOUND|${LAMBDA_WORKSPACE_FOLDER}/${tfvars_with_path}"
fi
elif [ "$request_type" == "create_tfvars" ]; then
echo "Creating TFVARS File"
tfvars_file_name_with_path="$local_repo/$tfvars_file_name.tfvars"
# Set trigger to true or false based on your logic
if [ "${s3trigger}" == "true" ]; then
s3_tr=$(cat <<EOF
s3_trigger = true
s3_trigger_alias = "LIGHT"
s3_trigger_bucket = "ra-lambda-deploy"
s3_trigger_event = "s3:ObjectCreated:*"
s3_trigger_prefix = "null"
s3_trigger_suffix = "null"
EOF
)
else
s3_tr=""

fi
if [ "${ddbtrigger}" == "true" ]; then
ddb_tr=$(cat <<EOF
ddb_trigger = true
ddb_trigger_table_name = "wdw-ee-B0219760-testapp-lst-harness"
ddb_trigger_alias = "LIGHT"
ddb_trigger_start_pos = "LATEST"
ddb_trigger_batch_size = "100"
ddb_trigger_maximum_batching_window_in_seconds = "5"
ddb_trigger_parallelization_factor = "1"
ddb_trigger_maximum_retry_attempts = "10000"
ddb_trigger_maximum_record_age_in_seconds = "604800"
ddb_trigger_bisect_batch_on_function_error = false
EOF
)
else
ddb_tr=""
fi
# Define function names (customize as per your needs)
functions=(
"function1"
"function2"
"function3"
)
# Loop through functions array to generate each function configuration
for function_name in "${functions[@]}"; do
lambda_gen=$(cat <<EOF
"name" = "${FUNCTION_NAME}"
"function_handler" = "index.${FUNCTION_NAME}"
"snow_description" = "${FUNCTION_NAME}-notification"
"lambda_runtime" = "nodejs16.x"
"lambda_memory_size" = "556"
"lambda_timeout" = "30"
"reserved_concurrent_executions" = "5"
"use_vpc" = true
"var_map" = "{}"
"tag_map" = "{}"
EFO
)
done
echo """
#############################################
# Standard variables
#############################################
account = \"${ACCOUNT}\"
ownerorg = \"wdpr\"
bag = \"${BAG}\"
region = \"${REGION}\"
environment = \"${ENVIRONMENT}\"
application_name = \"${APP}\"
user_tags = {harness_project = \"pradeep\"}
#############################################
# Accounting
#############################################
bapp_id = \"${BAPP_ID}\"
name_node_id = \"${NAME_NODE_ID}\"
bid = \"${BID}\"
#############################################
# LOGGING && SPLUNK INTEGRATION
#############################################
use_kinesis_stream = true
kinesis_stream_name = \"""\"

#############################################
# GLOBAL ENVIRONMENT VARIABLES
#############################################
lambda_global_vars_map = <<DOC
{
\"environment\": \"${ENVIRONMENT}\",
\"region\": \"${REGION}\"
}
DOC
#############################################
# GLOBAL TAGS
#############################################
lambda_global_tags_map = <<DOC
{
\"environment\": \"${ENVIRONMENT}\",
\"region\": \"${REGION}\"
}
DOC
#############################################
# FUNCTION DEFINITIONS
#############################################
lambda_map= {
\"${FUNCTION_NAME}\" = {
$lambda_gen
}
#############################################
# Artifact Location
#############################################
git_org = \"${GIT_ORG}\"
git_repo = \"${GIT_REPO}\"
artifact_version = \"${ARTIFACT_VERSION}\"
artifact_base_name = \"${ARTIFACT_BASE_NAME}\"
override_consul_artifact_version = \"true\"
initial_artifact_enable = \"disable\"
s3_existing_package = {
bucket = \"wdpr-lambda-deploy-${REGION_SHORT}\"
key = \"edt-cloudse/wdpr-ee-testapp-function/3.3.3-337/wdpr-ee-testapp-function.zip\"
}
###################################################################################
##Assuming ee-dev account as cicd-pradeep role is currently available in it.
###################################################################################
provider_assumed_role = \"WDPR-CICD-cross-pradeep\"
secrets_account = \"${ACCOUNT}\"
initial_artifact_account = \"${ACCOUNT}\"
initial_artifact_region = \"us-east-1\"
external_trigger_account = \"wdpr-ee-dev\"
external_trigger_region = \"us-east-1\"
dr_account = \"wdpr-ee-dev\"
#############################################
# SERVICE NOW INCIDENTS ON FAILURES
#############################################
snow_assignment_group = \"true\"
snow_configuration_item = \"true\"
lambda_alarms_actions_enabled = {
\"latest\" = {
\"warning\" = false
\"high\" = false
\"critical\" = false
}
}
#############################################
# VPC INFO (Required for use_vpc=1)
#############################################

vpc_info = {
subnet_list = [ \"wdpr-${BAG}-nb-${REGION_SHORT}-${ENVIRONMENT}-private-0\", \"wdpr-${BAG}-nb-${REGION_
SHORT}-${ENVIRONMENT}-private-1\", \"wdpr-${BAG}-nb-${REGION_SHORT}-${ENVIRONMENT}-private-2\"]
vpc_name = \"wdpr-${BAG}-nb-${REGION_SHORT}-${ENVIRONMENT}\"
}
scheduled_lambda_triggers = {
\"${FUNCTION_NAME}\" = {
\"lambda_function_base_name\" = \"${FUNCTION_NAME}\"
\"name\" = \"${FUNCTION_NAME}\"
\"sched_type\" = \"cron\"
\"sched_expression\" = \"0 8 * * ? *\"
\"state\" = \"ENABLED\"
\"input\" = <<DOC
{
\"name\": \"cloudwatch trigger\"
}
DOC
}
}
event_lambda_triggers = {
\"${FUNCTION_NAME}\" = {
\"lambda_function_base_name\" = \"${FUNCTION_NAME}\"
\"description\" = \"Capture each AWS Console Sign In\"
\"name\" = \"test-trigger\"
\"state\" = \"ENABLED\"
\"event_pattern\" = <<DOC
{
\"detail-type\": [\"AWS Console Sign In via CloudTrail\"]
}
DOC
}
}
lambdafunction_logfilters = {
\"${FUNCTION_NAME}\" = {
"apploggroup_name" = \"/aws/lambda/wdpr-ee-S0001507-use1-lst-testapp-sample-proc\"
}
}
app_policy = \"app_policy\"
""" > ${tfvars_file_name_with_path}
echo "File Creation completed"
cd $local_repo
git config --global url.https://$GITHUB_PASSWORD@github.disney.com/.insteadOf https://github.disney.com/
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USER"
git add $tfvars_file_name.tfvars
git commit -m "Created $tfvars_file_name.tfvars from harness"
git push origin naras051-harness_v2
elif [ "$request_type" == "update_tfvars" ]; then
tfvars_file_name_with_path="$local_repo/$tfvars_file_name.tfvars"
if [ ! -f ${tfvars_file_name_with_path} ]; then
echo "TFVARS File Not found.."
exit 1
fi
DATA=$(echo """ \"${FUNCTION_NAME}\" = { \\n \"name\" = \"${FUNCTION_NAME}\"\\n \"function_handler\" =
\"${FUNCTION_HANDLER}\"\\n \"snow_description\" = \"${FUNCTION_NAME}-notification\"\\n \"lambda_runtime\" =
\"nodejs16.x\"\\n \"lambda_memory_size\" = \"556\"\\n \"lambda_timeout\" = \"30\"\\n \"reserved_concurrent_executions\" =
\"5\"\\n \"use_vpc\" = true\\n \"var_map\" = \"{}\"\\n \"tag_map\" = \"{}\"\\n },""")
sed -i "/lambda_map/a $DATA" $tfvars_file_name_with_path
cat $tfvars_file_name_with_path
echo "File Updation completed"
cd $local_repo

git config --global url.https://$GITHUB_PASSWORD@github.disney.com/.insteadOf https://github.disney.com/
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USER"
git add $tfvars_file_name.tfvars
git commit -m "Updated $tfvars_file_name.tfvars from harness"
git push origin naras051-harness_v2
fi
