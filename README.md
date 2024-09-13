AWS EC2 with VPC and EBS using Terraform Data Sources
This repository demonstrates how to use Terraform to deploy an EC2 instance within an existing VPC and Subnet, and attach an EBS volume to the instance using data sources to reference existing AWS resources.

![image alt]([image_url](https://github.com/Maarioon/EC2_VPC_EBS_resources_datasource2/blob/089edf5edec1fb6cef7e49f77c806d7987872df2/How_to_create_an_Ec2%2CVPC%2CEBS_with_Terraform%20(1).png)

Leveraging Terraform Data Sources to Deploy an EC2 Instance with VPC and EBS
![image alt]([image_url](https://github.com/Maarioon/EC2_VPC_EBS_resources_datasource2/blob/42fae16c008398a1563d6fc1a955ef0298ef0ef5/EC2_VPC_EBS_Terraform.drawio.png)

When managing cloud infrastructure, you often need to use existing resources in your cloud environment rather than creating everything from scratch. This is where Terraform's data sources come in handy. In this guide, I'll walk you through using data sources to deploy an EC2 instance within a VPC, and attach an EBS volume, all while leveraging existing AWS resources.

Why Use Data Sources in Terraform?
Data sources in Terraform allow you to fetch information about existing resources in your cloud provider. For example, you might want to use an existing VPC or AMI (Amazon Machine Image) rather than creating new ones. By using data sources, you can reference these resources dynamically, making your Terraform configurations more flexible and reusable.

Step 1: Setting Up Your Terraform Configuration
Before diving into the data sources, let's set up the basic Terraform configuration files.

Create a new directory for your project:
```
mkdir aws-ec2-vpc-ebs-datasource
cd aws-ec2-vpc-ebs-datasource
touch main.tf variables.tf outputs.tf terraform.tfvars
```
In main.tf, we’ll start by defining the provider and necessary resources.
```
provider "aws" {
  region = var.region
}

```
Step 2: Using Data Sources to Retrieve Existing Resources
To avoid manually creating certain resources, we'll use data sources to fetch information about existing ones.

1. Fetching an Existing VPC
Instead of creating a new VPC, let's assume you have an existing one in your AWS account. You can fetch this VPC using a data source.
```
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["my-existing-vpc"]
  }
}

```
This will fetch the VPC that has a tag with the name my-existing-vpc. Now, you can reference this VPC throughout your configuration.

2. Fetching an Existing Subnet
Similarly, you can fetch an existing subnet within the VPC.
```
data "aws_subnet" "existing_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["my-existing-subnet"]
  }
}
```
This will fetch the subnet tagged as my-existing-subnet within the existing VPC.

![image alt]([image_url](https://github.com/Maarioon/EC2_VPC_EBS_resources_datasource2/blob/489989c2d32b73f9433a896e55afed7c53690471/Screenshot%202024-09-05%20152559.png)

3. Fetching an AMI
You can also use a data source to fetch a specific Amazon Machine Image (AMI) that you want to use for your EC2 instance.
```
data "aws_ami" "latest_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["137112412989"] # Amazon's owner ID for public AMIs
}

```
This will retrieve the most recent Amazon Linux 2 AMI.

Step 3: Creating the EC2 Instance
Now that we have the necessary data from AWS, we can create the EC2 instance using the fetched resources.
```
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.latest_ami.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.existing_subnet.id
  associate_public_ip_address = true

  tags = {
    Name = "web-server"
  }
}

```
In this configuration, we are using the AMI and subnet fetched from our data sources.

Step 4: Attaching an EBS Volume
Next, we'll attach an EBS volume to our EC2 instance. This volume can also be created using Terraform, or if you have an existing EBS volume, you can fetch it with a data source.
```
resource "aws_ebs_volume" "web_data" {
  availability_zone = aws_instance.web_server.availability_zone
  size              = 10 # 10GB

  tags = {
    Name = "web-data"
  }
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web_data.id
  instance_id = aws_instance.web_server.id
}
```
Step 5: Setting Up Security Groups
To secure your EC2 instance, create a security group that allows traffic only from specific sources. If you have an existing security group, you can retrieve it using a data source.
```
data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["my-existing-sg"]
  }
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = data.aws_security_group.existing_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
```
This setup allows HTTP traffic to your instance using an existing security group.

Step 6: Define Variables
Edit the terraform.tfvars file to specify values for the following variables:
```
region        = "your-aws-region" # e.g. us-west-2
instance_type = "t2.micro"
vpc_name      = "my-existing-vpc"
subnet_name   = "my-existing-subnet"
sg_name       = "my-existing-sg"
```
Step 7 : create a variable.tf file to save variables that are represented in the terraform.tfvars file, this is optional but you can do it when you want to ignore your credentials before pushing it to a repo
```
variable "region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
}

variable "vpc_name" {
  description = "Name of the existing VPC"
  type        = string
}

variable "subnet_name" {
  description = "Name of the existing Subnet"
  type        = string
}

variable "sg_name" {
  description = "Name of the existing Security Group"
  type        = string
}
```

Step 8: Provision Your Infrastructure
With all your configurations ready, you can deploy your infrastructure by following these steps:

Initialize Terraform:

Run terraform init in your project directory to initialize Terraform and download the necessary providers.
Plan the Deployment:

Use terraform plan to preview the changes Terraform will make. This will show you which resources will be created or modified.
Apply the Configuration:

Run terraform apply to provision the resources. Confirm the action by typing yes when prompted.
Step 7: Verifying the Deployment
After Terraform completes the deployment, you can verify your setup by logging into the AWS Management Console. Navigate to the EC2 dashboard, where you should see your new EC2 instance running, along with the associated VPC, subnets, and EBS volume.

Step 8: Cleaning Up
Once you're done, it's important to clean up your resources to avoid incurring unnecessary costs. You can do this by running:
```
terraform destroy
```
This command will destroy all the resources you created with Terraform.
Using Data sources enables you to use existing resource and also manage them, this helps making or creating infrastructure flexible and scalable. 

