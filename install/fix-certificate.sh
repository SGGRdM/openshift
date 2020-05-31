#!/bin/bash -x
#	./install/fix-certificate.sh
#########################################################################
#      Copyright (C) 2020        Sebastian Francisco Colomar Bauza      #
#      SPDX-License-Identifier:  GPL-2.0-only                           #
#########################################################################
caps=CAPABILITY_IAM							;
ClusterName=v4-4-5							;
ClusterName=v4-3-22							;
HostedZoneName=sebastian-colomar.es					;
Identifier=d4085e20-28a4-4d28-873a-2c6e3ec04626				;
Identifier=61f62a05-49e0-41d7-a04e-bd3fb568f74a				;
s3name=docker-aws							;
s3region=ap-south-1							;
template=cloudformation.yaml						;
#########################################################################
sed --in-place s/ClusterName/$ClusterName/ 				\
	ingresscontroller-template.yaml					;
sed --in-place s/HostedZoneName/$HostedZoneName/			\
	ingresscontroller-template.yaml					;
tail -1 .openshift_install.log						; 
oc get ingresscontrollers/default 					\
	--namespace=openshift-ingress-operator 				\
	--output=yaml 							\
	1> ingresscontroller.yaml					;
oc delete -f ingresscontroller.yaml					;
oc create -f ingresscontroller-template.yaml				;
#########################################################################
InstanceWorker1=$( 							\
	aws ec2 describe-instances 					\
	--filter "Name=tag:Name,Values=$ClusterName-*-worker-${s3region}a*" \
	--output text 							\
	--query "Reservations[].Instances[].InstanceId" 		\
)									;
InstanceWorker2=$( 							\
	aws ec2 describe-instances 					\
	--filter "Name=tag:Name,Values=$ClusterName-*-worker-${s3region}b*" \
	--output text 							\
	--query "Reservations[].Instances[].InstanceId" 		\
)									;
InstanceWorker3=$( 							\
	aws ec2 describe-instances 					\
	--filter "Name=tag:Name,Values=$ClusterName-*-worker-${s3region}c*" \
	--output text 							\
	--query "Reservations[].Instances[].InstanceId" 		\
)									;
SubnetPublic1=$( 							\
	aws ec2 describe-subnets 					\
	--filter "Name=tag:Name,Values=$ClusterName-*-public-${s3region}a" \
	--output text 							\
	--query "Subnets[].SubnetId" 					\
)									;
SubnetPublic2=$( 							\
	aws ec2 describe-subnets 					\
	--filter "Name=tag:Name,Values=$ClusterName-*-public-${s3region}b" \
	--output text 							\
	--query "Subnets[].SubnetId" 					\
)									;
SubnetPublic3=$( 							\
	aws ec2 describe-subnets 					\
	--filter "Name=tag:Name,Values=$ClusterName-*-public-${s3region}c" \
	--output text 							\
	--query "Subnets[].SubnetId" 					\
)									;
VpcCidrBlock=$( 							\
	aws ec2 describe-vpcs 						\
	--filter "Name=tag:Name,Values=$ClusterName-*-vpc" 		\
	--output text 							\
	--query "Vpcs[].CidrBlockAssociationSet[].CidrBlock" 		\
)									;
VpcId=$( 								\
	aws ec2 describe-vpcs 						\
	--filter "Name=tag:Name,Values=$ClusterName-*-vpc" 		\
	--output text 							\
	--query "Vpcs[].VpcId"						\
)									;
#########################################################################
VpcDefaultSecurityGroup=$( 						\
	aws ec2 describe-security-groups 				\
	--filter "Name=vpc-id,Values=$VpcId" "Name=group-name,Values=default" \
	--output text 							\
	--query "SecurityGroups[].GroupId" 				\
)									;
#########################################################################
s3domain=$s3name.s3.$s3region.amazonaws.com				;
stack=$ClusterName-openshift-fix-certificate				;
template_url=https://$s3domain/$ClusterName/$template			;
aws s3 cp $template s3://$s3name/$ClusterName/$template			;
aws cloudformation create-stack                                         \
	--capabilities                                                  \
		$caps                                                   \
	--parameters                                                    \
	ParameterKey=ClusterName,ParameterValue=$ClusterName            \
	ParameterKey=HostedZoneName,ParameterValue=$HostedZoneName      \
	ParameterKey=Identifier,ParameterValue=$Identifier              \
	ParameterKey=InstanceWorker1,ParameterValue=$InstanceWorker1    \
	ParameterKey=InstanceWorker2,ParameterValue=$InstanceWorker2    \
	ParameterKey=InstanceWorker3,ParameterValue=$InstanceWorker3    \
	ParameterKey=SubnetPublic1,ParameterValue=$SubnetPublic1        \
	ParameterKey=SubnetPublic2,ParameterValue=$SubnetPublic2        \
	ParameterKey=SubnetPublic3,ParameterValue=$SubnetPublic3        \
	ParameterKey=VpcId,ParameterValue=$VpcId                        \
	ParameterKey=VpcCidrBlock,ParameterValue=$VpcCidrBlock          \
	ParameterKey=VpcDefaultSecurityGroup,ParameterValue=$VpcDefaultSecurityGroup \
	--stack-name                                                    \
		$stack                                                  \
	--template-url                                                  \
		$template_url                                           \
	--output                                                        \
		text                                                    \
#########################################################################