# S3 Remote backend with dynamodb state-lock
terraform {
   backend "s3" {
    bucket = "upgrad-project-bucket-555"
    dynamodb_table = "upgrad-project-db-table-555"
    key    = "terraform-remote-backend/tfstatefile"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# vpc creation
 resource "aws_vpc" "project_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "upgrad_project_vpc_555"
  }
}
 
# IGW creation

resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "upgrad_project_igw_555"
  }
}
# Eip for natgateway

resource "aws_eip" "project_eip" {
    tags = {
    Name = "upgrad_project_eip_555"
  }
  
  depends_on = [aws_internet_gateway.project_igw]
}

# nat gateway for  private subnet connectivity

resource "aws_nat_gateway" "project_nat" {
  allocation_id = aws_eip.project_eip.id
  subnet_id     = aws_subnet.project_public_subnet1.id

  tags = {
    Name = "upgrad_project_NAT_555"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.project_igw]
}



# Public route table

resource "aws_route_table" "project_public_route_table" {
  vpc_id = aws_vpc.project_vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.project_igw.id
    }
  

  tags = {
    Name = "upgrad_project_public_route_table_555"
  }
}

# Private route table

resource "aws_route_table" "project_private_route_table" {
  vpc_id = aws_vpc.project_vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.project_nat.id
    }
  

  tags = {
    Name = "upgrad_project_private_route_table_555"
  }
}


# 2 public subnets 

resource "aws_subnet" "project_public_subnet1" {
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "upgrad_project_public_subnet1_555"
  }
}

resource "aws_subnet" "project_public_subnet2" {
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "upgrad_project_public_subnet2_555"
  }
}
# 2 private subnets

resource "aws_subnet" "project_private_subnet1" {
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "upgrad_project_private_subnet1_555"
  }
}

resource "aws_subnet" "project_private_subnet2" {
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"


  tags = {
    Name = "upgrad_project_private_subnet2_555"
  }
}

# Public Route table associations1

resource "aws_route_table_association" "project_public_subnet1_association" {
  subnet_id      = aws_subnet.project_public_subnet1.id
  route_table_id = aws_route_table.project_public_route_table.id
}

# Public Route table associations2

resource "aws_route_table_association" "project_public_subnet2_association" {
  subnet_id      = aws_subnet.project_public_subnet2.id
  route_table_id = aws_route_table.project_public_route_table.id
}

# Private Route table associations1
resource "aws_route_table_association" "project_private_subnet1_association" {
  subnet_id      = aws_subnet.project_private_subnet1.id
  route_table_id = aws_route_table.project_private_route_table.id
}

# Private Route table associations2

resource "aws_route_table_association" "project_private_subnet2_association" {
  subnet_id      = aws_subnet.project_private_subnet2.id
  route_table_id = aws_route_table.project_private_route_table.id
}


# Self-ip collection using data source

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# Bastion_Host_SG

resource "aws_security_group" "Bastion_Host_SG_555" {
  name        = "Bastion_Host_SG_555"
  description = " Allow self ip to ssh to Bastion instance and allow all egress"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
      description      = "Allow self ip to ssh to Bastion"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
      ipv6_cidr_blocks = ["::/0"]
    }
  

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  

  tags = {
    Name = "Bastion_Host_SG_555"
  }
}

# Private_Instances_SG
resource "aws_security_group" "Private_Instances_SG_555" {
  name        = "Private_Instances_SG_555"
  description = "Allow all incoming traffic from within VPC and all egress"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
      description      = "Allow all incoming traffic from within VPC"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = [aws_vpc.project_vpc.cidr_block]
      
    }
  
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  

  tags = {
    Name = "Private_Instances_SG_555"
  }
}

# Public Web SG

resource "aws_security_group" "Public_Web_SG_555" {
  name        = "Public_Web_SG_555"
  description = "Allow incoming traffic to port 80 from self IP and all egress"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
      description      = "Allow incoming traffic to port 80 from self IP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
      ipv6_cidr_blocks = ["::/0"]
    }
  

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "Public_Web_SG_555"
  }
}



# Bastion_Host machine

resource "aws_instance" "bastion" {

    ami = "ami-09e67e426f25ce0d7"

    instance_type = "t2.micro"

    vpc_security_group_ids =  [aws_security_group.Bastion_Host_SG_555.id]

    subnet_id = aws_subnet.project_public_subnet1.id 

    key_name      = "upgrad_project"

    count         = 1

    associate_public_ip_address = true

    tags = {
      Name        = "Bastion_Host_555"
    }
}

# jenkins ec2 machine 
resource "aws_instance" "jenkins" {

    ami = "ami-09e67e426f25ce0d7"

    instance_type = "t2.micro"

    vpc_security_group_ids = [aws_security_group.Private_Instances_SG_555.id]

    subnet_id = aws_subnet.project_private_subnet1.id

    key_name      = "upgrad_project"

    count         = 1

    tags = {
      Name        = "Jenkins_Server_555"
    }
}


# App server ec2 machine
 
resource "aws_instance" "app" {

    ami = "ami-09e67e426f25ce0d7"

    instance_type = "t2.micro"

    vpc_security_group_ids =  [aws_security_group.Private_Instances_SG_555.id]

    subnet_id = aws_subnet.project_private_subnet1.id

    key_name      = "upgrad_project"

    count         = 1

    tags = {
      Name        = "App_Server_555"
    }
}












 


