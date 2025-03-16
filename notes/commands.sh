# Create security group
aws ec2 create-security-group \
    --group-name "homelab-sg" \
    --description "homelab-sg created 2025-03-15T16:10:44.644Z" \
    --vpc-id "vpc-03783dce2e6cf4491"

# Configure security group rules
aws ec2 authorize-security-group-ingress \
    --group-id "sg-preview-1" \
    --ip-permissions \
    '{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}' \
    '{"IpProtocol":"tcp","FromPort":443,"ToPort":443,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}' \
    '{"IpProtocol":"tcp","FromPort":80,"ToPort":80,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}'

# Launch EC2 instances
aws ec2 run-instances \
    --image-id "ami-07eef52105e8a2059" \
    --instance-type "t3.micro" \
    --key-name "ciberado-awslabs-frankfurt" \
    --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"Iops":3000,"SnapshotId":"snap-0e964d47a186bf0a7","VolumeSize":8,"VolumeType":"gp3","Throughput":125}}' \
    --network-interfaces '{"AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["homelab-sg"]}' \
    --credit-specification '{"CpuCredits":"standard"}' \
    --tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"homelab-service"}]}' \
    --iam-instance-profile '{"Arn":"arn:aws:iam::436628946705:instance-profile/workstation"}' \
    --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required","InstanceMetadataTags":"enabled"}' \
    --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":true,"EnableResourceNameDnsAAAARecord":false}' \
    --count "1" 


aws ec2 run-instances \
  --image-id "ami-0df368112825f8d8f" \
  --instance-type "g4dn.xlarge" \
  --key-name "ciberado-awslabs-ireland" \
  --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":true,"DeleteOnTermination":true,"Iops":3000,"KmsKeyId":"alias/aws/ebs","VolumeSize":80,"VolumeType":"gp3","Throughput":125}}' \
  --network-interfaces '{"AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-01f8ae06164f35e3e"]}' \
  --tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"ai-server"}]}' \
  --iam-instance-profile '{"Arn":"arn:aws:iam::436628946705:instance-profile/workstation"}' \
  --instance-market-options '{"MarketType":"spot","SpotOptions":{"InstanceInterruptionBehavior":"stop","SpotInstanceType":"persistent","ValidUntil":"2025-03-19T23:00:00.000Z"}}' \
  --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required","InstanceMetadataTags":"enabled"}' \
  --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":true,"EnableResourceNameDnsAAAARecord":false}' \
  --count "1" 

