<#
    NOTE: DO NOT RUN THIS SCRIPT
    This is simply a record of commands 
    demonstrated in the AWS PowerShell Webinar
#>

#Credentials

Get-EC2Instance -AccessKey $AccessKey -SecretKey $SecretKey -Region us-west-1

Get-AWSCredentials -ListStoredCredentials
Clear-AWSCredentials -StoredCredentials PSH

Set-AWSCredentials -StoreAs PSH -AccessKey $AccessKey -SecretKey $SecretKey

Get-EC2Instance -ProfileName PSH

Get-EC2Instance -ProfileName PSH -Region us-west-1

Clear-AWSCredentials -StoredCredentials PSH

Initialize-AWSDefaults -AccessKey $AccessKey -SecretKey $SecretKey -Region us-west-1

Get-AWSCredentials -ListStoredCredentials

#Regions

Get-AWSRegion

Set-DefaultAWSRegion -Region us-west-1

Clear-DefaultAWSRegion

#Discovery

Get-Command -Module AWSPowerShell

Get-Help

help New-EC2Instance -Examples

#History

$AWSHistory

Get-History

Get-History | select -ExpandProperty commandline

#Find ami's

Get-EC2ImageByName

Get-EC2ImageByName windows_2012r2_base | select -First 1 -ExpandProperty imageid
$win_ami = Get-EC2ImageByName windows_2012r2_base | select -First 1 -ExpandProperty imageid

#Create instance

$i = New-EC2Instance -ImageId $win_ami -MinCount 1 -MaxCount 1 -KeyName norcal -InstanceType m3.xlarge
$i = New-EC2Instance -ImageId $win_ami -MinCount 1 -MaxCount 1 -KeyName norcal -InstanceType m3.xlarge | select -ExpandProperty instances

Get-EC2Instance | Stop-EC2Instance -Terminate -Confirm:$false -Force

#Security groups
$sg = New-EC2SecurityGroup -GroupName MyRDPGroup -Description 'Enable RDP from Internet'
Get-EC2SecurityGroup -GroupIds $sg | select -ExpandProperty ippermissions

$ip.IpProtocol = 'tcp'
$ip.FromPort = '3389'
$ip.ToPort = '3389'
$ip.IpRange.add('0.0.0.0/0')

Grant-EC2SecurityGroupIngress -GroupId $sg -IpPermissions $ip

$i = New-EC2Instance -ImageId $win_ami -MinCount 1 -MaxCount 1 -KeyName norcal -InstanceType m3.xlarge -SecurityGroupIds $sg | select -ExpandProperty instances

#Tagging
New-EC2Tag -Resources $i.instanceid -Tags @{key='Name';value='SRV01'}

#Filters
Get-EC2Instance -Filter @{name='tag:Name';values='SRV01'}

#Password retrieval (you need to change the pem file path)
Get-EC2PasswordData -InstanceId $i.instanceid -PemFile C:\norcal.pem

#Instance meta-data
Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data
Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/instance-type

#Ebs - add storage to new instance

$vol = New-Object Amazon.EC2.Model.EbsBlockDevice
$vol
$vol.DeleteOnTermination = $true
$vol.VolumeSize = 100
$vol.VolumeType = 'gp2'
$map = New-Object Amazon.EC2.Model.BlockDeviceMapping

$map.DeviceName = 'xvdf'
$map.Ebs = $vol

$i = New-EC2Instance -ImageId $win_ami -MinCount 1 -MaxCount 1 -KeyName norcal -InstanceType m3.xlarge -BlockDeviceMapping $map | select -ExpandProperty instances

#Ebs add storage to running instance

$v = New-EC2Volume -AvailabilityZone us-west-1b -Size 100 -VolumeType gp2
Add-EC2Volume -Device xvdf -InstanceId $i.instanceid -VolumeId $v.VolumeId

