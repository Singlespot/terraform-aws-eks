---
AWSTemplateFormatVersion: '2010-09-09'
Description: ${description}

Parameters:

  KeyName:
    Description: The EC2 Key Pair to allow SSH access to the instances
    Type: AWS::EC2::KeyPair::KeyName

  NodeImageId:
    Type: AWS::EC2::Image::Id
    Description: AMI id for the node instances.

  NodeInstanceType:
    Description: EC2 instance type for the node instances
    Type: String
    Default: t3.small
    AllowedValues:
    - t3.small
    - t3.medium
    - t3.large
    - t3.xlarge
    - t3.2xlarge
    - m4.large
    - m4.xlarge
    - m4.2xlarge
    - m4.4xlarge
    - m4.10xlarge
    - m5.large
    - m5.xlarge
    - m5.2xlarge
    - m5.4xlarge
    - m5.12xlarge
    - m5.24xlarge
    - m5a.large
    - m5a.xlarge
    - m5a.2xlarge
    - m5a.4xlarge
    - c4.large
    - c4.xlarge
    - c4.2xlarge
    - c4.4xlarge
    - c4.8xlarge
    - c5.large
    - c5.xlarge
    - c5.2xlarge
    - c5.4xlarge
    - c5.9xlarge
    - c5.18xlarge
    ConstraintDescription: Must be a valid EC2 instance type

  NodeAutoScalingGroupMinSize:
    Type: Number
    Description: Minimum size of Node Group ASG.
    Default: 1

  NodeAutoScalingGroupMaxSize:
    Type: Number
    Description: Maximum size of Node Group ASG.
    Default: 1

  NodeVolumeSize:
    Type: Number
    Description: Node volume size
    Default: 20

  ClusterName:
    Description: The cluster name provided when the cluster was created. If it is incorrect, nodes will not be able to join the cluster.
    Type: String

  BootstrapArguments:
    Description: Arguments to pass to the bootstrap script. See files/bootstrap.sh in https://github.com/awslabs/amazon-eks-ami
    Default: ""
    Type: String

  NodeGroupName:
    Description: Unique identifier for the Node Group.
    Type: String

  ClusterControlPlaneSecurityGroup:
    Description: The security group of the cluster control plane.
    Type: AWS::EC2::SecurityGroup::Id

  VpcId:
    Description: The VPC of the worker instances
    Type: AWS::EC2::VPC::Id

  Subnets:
    Description: The subnets where workers can be created.
    Type: List<AWS::EC2::Subnet::Id>

Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      -
        Label:
          default: "EKS Cluster"
        Parameters:
          - ClusterName
          - ClusterControlPlaneSecurityGroup
      -
        Label:
          default: "Worker Node Configuration"
        Parameters:
          - NodeGroupName
          - NodeAutoScalingGroupMinSize
          - NodeAutoScalingGroupMaxSize
          - NodeInstanceType
          - NodeImageId
          - NodeVolumeSize
          - KeyName
          - BootstrapArguments
      -
        Label:
          default: "Worker Network Configuration"
        Parameters:
          - VpcId
          - Subnets

Resources:

  NodeInstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Path: "/"
      Roles:
      - !Ref NodeInstanceRole

  NodeInstanceRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
        - Effect: Allow
          Principal:
            Service:
            - ec2.amazonaws.com
          Action:
          - sts:AssumeRole
      Path: "/"
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

  NodeSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for all nodes in the cluster
      VpcId:
        !Ref VpcId
      Tags:
      - Key: !Sub "kubernetes.io/cluster/$${ClusterName}"
        Value: 'owned'
      - Key: 'Name'
        Value: !Sub "$${ClusterName}"
      - Key: 'KubernetesCluster'
        Value: !Sub "$${ClusterName}"
#      - Key: 'env'
#        Value: !Sub "$${env}"
      - Key: 'kubernetes.io/role/elb'
        Value: '1'

  NodeSecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow node to communicate with each other
      GroupId: !Ref NodeSecurityGroup
      SourceSecurityGroupId: !Ref NodeSecurityGroup
      IpProtocol: '-1'
      FromPort: 0
      ToPort: 65535

  NodeSecurityGroupFromControlPlaneIngress:
    Type: AWS::EC2::SecurityGroupIngress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow worker Kubelets and pods to receive communication from the cluster control plane
      GroupId: !Ref NodeSecurityGroup
      SourceSecurityGroupId: !Ref ClusterControlPlaneSecurityGroup
      IpProtocol: tcp
      FromPort: 1025
      ToPort: 65535

  ControlPlaneEgressToNodeSecurityGroup:
    Type: AWS::EC2::SecurityGroupEgress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow the cluster control plane to communicate with worker Kubelet and pods
      GroupId: !Ref ClusterControlPlaneSecurityGroup
      DestinationSecurityGroupId: !Ref NodeSecurityGroup
      IpProtocol: tcp
      FromPort: 1025
      ToPort: 65535

  NodeSecurityGroupFromControlPlaneOn443Ingress:
    Type: AWS::EC2::SecurityGroupIngress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow pods running extension API servers on port 443 to receive communication from cluster control plane
      GroupId: !Ref NodeSecurityGroup
      SourceSecurityGroupId: !Ref ClusterControlPlaneSecurityGroup
      IpProtocol: tcp
      FromPort: 443
      ToPort: 443

  ControlPlaneEgressToNodeSecurityGroupOn443:
    Type: AWS::EC2::SecurityGroupEgress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow the cluster control plane to communicate with pods running extension API servers on port 443
      GroupId: !Ref ClusterControlPlaneSecurityGroup
      DestinationSecurityGroupId: !Ref NodeSecurityGroup
      IpProtocol: tcp
      FromPort: 443
      ToPort: 443

  ClusterControlPlaneSecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow pods to communicate with the cluster API Server
      GroupId: !Ref ClusterControlPlaneSecurityGroup
      SourceSecurityGroupId: !Ref NodeSecurityGroup
      IpProtocol: tcp
      ToPort: 443
      FromPort: 443

  NodeGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      DesiredCapacity: !Ref NodeAutoScalingGroupMaxSize
      LaunchConfigurationName: !Ref NodeLaunchConfig
      MinSize: !Ref NodeAutoScalingGroupMinSize
      MaxSize: !Ref NodeAutoScalingGroupMaxSize
      VPCZoneIdentifier:
        !Ref Subnets
      Tags:
      - Key: Name
        Value: !Sub "$${ClusterName}-$${NodeGroupName}-Node"
        PropagateAtLaunch: 'true'
      - Key: !Sub 'kubernetes.io/cluster/$${ClusterName}'
        Value: 'owned'
        PropagateAtLaunch: 'true'
    UpdatePolicy:
      AutoScalingRollingUpdate:
        MinInstancesInService: '1'
        MaxBatchSize: '1'
        PauseTime: 'PT5M'

  NodeLaunchConfig:
    Type: AWS::AutoScaling::LaunchConfiguration
    Properties:
      AssociatePublicIpAddress: 'true'
      IamInstanceProfile: !Ref NodeInstanceProfile
      ImageId: !Ref NodeImageId
      InstanceType: !Ref NodeInstanceType
      KeyName: !Ref KeyName
      SecurityGroups:
      - !Ref NodeSecurityGroup
      BlockDeviceMappings:
        - DeviceName: /dev/xvda
          Ebs:
            VolumeSize: !Ref NodeVolumeSize
            VolumeType: gp2
            DeleteOnTermination: true
      UserData:
        Fn::Base64:
          !Sub |
            #!/bin/bash
            set -o xtrace
            /etc/eks/bootstrap.sh $${ClusterName} $${BootstrapArguments}
            /opt/aws/bin/cfn-signal --exit-code $? \
                     --stack  $${AWS::StackName} \
                     --resource NodeGroup  \
                     --region $${AWS::Region}

Outputs:
  NodeInstanceRole:
    Description: The node instance role
    Value: !GetAtt NodeInstanceRole.Arn