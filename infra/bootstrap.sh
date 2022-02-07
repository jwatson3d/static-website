#!/bin/bash

# obtain current user name
OWNER_NAME=$(aws sts get-caller-identity | jq -r ".Arn" | cut -d'/' -f2)
USER_NAME=$(sed -e "s/_/-/g" <<<$OWNER_NAME)

# obtain source repository information (https://github.com/james-turner/github-to-ci-in-5-minutes/blob/master/bootstrap.sh)
SOURCE_TYPE=$(git remote -v | grep push | cut -d ':' -f1 | cut -d '@' -f2 | cut -d '.' -f1)
#SOURCE_TYPE=$(tr '[:lower:]' '[:upper:]' <<< ${SOURCE_TYPE:0:1})${SOURCE_TYPE:1}
#SOURCE_TYPE="${${SOURCE_TYPE}/github/GitHub}"
SOURCE_TYPE=GitHub
CREDENTIALS_ARN=$(aws codestar-connections list-connections --provider-type-filter $SOURCE_TYPE --max-results 10 --query "Connections[?ConnectionStatus=='AVAILABLE']|[0].ConnectionArn" --output text)
BRANCH=$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
PROJECT_NAME=$(basename `pwd`)
REPOSITORY_OWNER=$(git remote -v | grep push | cut -d ':' -f2 | cut -d '/' -f1)
REPOSITORY_ID=$REPOSITORY_OWNER/$PROJECT_NAME

# create a unique stack name
STACK_NAME=$PROJECT_NAME-$BRANCH-bootstrap

# create the stack using these random names
echo "Creating CloudFormation stack $STACK_NAME"
STACK_ID=$(aws cloudformation create-stack \
  --stack-name "$STACK_NAME" \
  --template-body file://infra/bootstrap.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=BranchName,ParameterValue=$BRANCH \
      ParameterKey=CredentialsArn,ParameterValue=$CREDENTIALS_ARN \
      ParameterKey=CurrentUserName,ParameterValue=$OWNER_NAME \
      ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
      ParameterKey=RepositoryId,ParameterValue=$REPOSITORY_ID &)

# obtain the stack ID just created
STACK_ARN=$(jq -r '.StackId' <<<$STACK_ID)

echo "Waiting for STACK_ARN ${STACK_ARN} to be completed"
aws cloudformation wait stack-create-complete --stack-name "${STACK_ARN}"

echo "Stack ${STACK_NAME} has been created:"
STACK_INFO=$(aws cloudformation describe-stacks --stack-name $STACK_NAME)

BUCKET_NAME=$(jq -r '.Stacks[0].Outputs[0].OutputValue' <<<$STACK_INFO)
echo "S3 Bucket '${BUCKET_NAME}' has been created"

KEY_ID=$(jq -r '.Stacks[0].Outputs[1].OutputValue' <<<$STACK_INFO)
KEY_ALIAS=$(jq -r '.Stacks[0].Outputs[2].OutputValue' <<<$STACK_INFO)
echo "Key '${KEY_ID}' with alias '${KEY_ALIAS}' has been created"

export KEY_ID
export KEY_ALIAS
export BUCKET_NAME

# pause to allow inspection
# echo "Press any key to continue"
# while [ true ] ; do
#   read -t 5 -n 1
#   if [ $? = 0 ] ; then
#     break ;
#   else
#     echo "waiting for the keypress"
#   fi
# done

# remove the stack
#aws cloudformation delete-stack --stack-name "$STACK_NAME"