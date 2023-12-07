##############################################################################################
# ADOGoldenAMI-LINUX-Rotate-AmiIds-Secret
# Import Modules
import boto3
import os
import json

def lambda_handler(event, context):
    ##############################################################################################
    # AMI ID that is passed in from SSM Doc
    sya_image_id = event['image_id']
    aws_image_id = event['aws_image_id']

    ##############################################################################################
    region = os.environ["AWS_DEFAULT_REGION"]
    ec2 = boto3.resource('ec2',region)
    ssm = boto3.client('ssm',region)
    client = boto3.client('ec2',region)
    secretsm = boto3.client('secretsmanager',region)

    ##############################################################################################
    # Function to properly display build type
    def get_build_type(build_type):
        if build_type == 'AWS LINUX 2':
            return 'AWSLinux2'
        elif build_type == 'AWS LINUX 2023':
            return 'AWSLinux2023'
        return 'unknown'

    ##############################################################################################
    # Get Type Tag value from AMI ID that is passed in from SSM Doc
    sya_image = ec2.Image(sya_image_id)
    os_type = None
    build_type = None
    for tag in sya_image.tags:
        if tag['Key'] == 'type':
            os_type = tag.get('Value')
        if tag['Key'] == 'build':
            build_type = tag.get('Value')

    ##############################################################################################
    # Call Function to get properly formatted Build Type
    os_build = get_build_type(build_type)

    ##############################################################################################
    # Get parameters from Public SSM Parameter stores
    # If you need to find Public AMI paths you can use this powershell command: 
    # Get-SSMParametersByPath -Path "/aws/service/ami-windows-latest" -region us-west-2 | export-csv latestamis.csv
    publicLINUX2 = ssm.get_parameter(Name='/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2')['Parameter']['Value']
    publicLINUXal2023 = ssm.get_parameter(Name='/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64')['Parameter']['Value']

    ##############################################################################################
    # Set Secret ARNs for OS type
    linux2 = '__secretarn__'
    al2023 = '__secretarnal2023__'

    ##############################################################################################
    # Function to set new AMI as the value in Secret
    # ARN is the Secret value, ami_id is the new AMI, old and old1 are the previous AMIs
    def set_ami_value(arn, ami_id):
        old = secretsm.get_secret_value(
            SecretId=arn
        )
        oldvalues = json.loads(old['SecretString'])
        last = oldvalues['ami']
        last1 = oldvalues['n1']
        secret_string_dict = {'ami': ami_id, 'n1': last, 'n2': last1}
        sstring = json.dumps(secret_string_dict)
        sm = boto3.client('secretsmanager')
        sm.put_secret_value(
            SecretId=arn,
            SecretString=sstring
        )

    ##############################################################################################
    # Compare AMIs & Put updated value into Secret
    if publicLINUX2 == aws_image_id:
        set_ami_value(linux2, sya_image_id)
    if publicLINUXal2023 == aws_image_id:
        set_ami_value(al2023, sya_image_id)

    ##############################################################################################
    # Share AMI across accounts
    client.modify_image_attribute(ImageId=sya_image_id, OperationType='add', Attribute='launchPermission', UserIds=['308701666906', '731887935032', '875633491806'])
    ##############################################################################################
    # Return Values
    # return "Done"

    def publish_message(TargetArn, Message):

        notification = "DevOps LINUX-AMI Secret value added!"
        client = boto3.client('sns')
        response = client.publish (
            TargetArn = "__topicarn__",
            Message = json.dumps({'default': notification}),
            MessageStructure = 'json'
        )

        return response

    return "Done"