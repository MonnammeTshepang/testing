provider "aws" {
  region  = "eu-central-1"
  profile = "AWSprofile1"
}

# 1. Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "production VPC"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "VPCgateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "main-GATEWAY"
  }
}
# 3. Create Custom Route Table
resource "aws_route_table" "my-route-table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPCgateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.VPCgateway.id
  }

  tags = {
    Name = "my-route-table"
  }
}
# 4. Create Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "eu-central-1c"

  tags = {
    Name = "production SUBNET"
  }
}
# 5. Associate Subnet with Route Table
resource "aws_route_table_association" "associateRes" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my-route-table.id
}
# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_ingress-egress" {
  name        = "allow_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_traffic"
  }
}
# 7. Create a Network Interface with an ip in the Subnet that was created in step 4
resource "aws_network_interface" "interface1" {
  subnet_id       = aws_subnet.my_subnet.id
  private_ips     = ["172.16.10.30"]
  security_groups = [aws_security_group.allow_ingress-egress.id]
}
# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "elastic_IP" {
  vpc                       = true
  network_interface         = aws_network_interface.interface1.id
  associate_with_private_ip = "172.16.10.30"
  depends_on                = [aws_internet_gateway.VPCgateway]
}
# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "instance-1" {
  ami           = "ami-0ec7f9846da6b0f61"
  instance_type = "t2.micro"
  key_name      = "key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.interface1.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              echo bash -c ' echo server successfully launched > /var/www/html/index.html'
              EOF
  tags = {
    Name = "My-instance"
  }
}

#------------------------
# 1. Create VPC
# 2. Create Internet Gateway
# 3. Create Custom Route Table
# 4. Create Subnet
# 5. Associate Subnet with Route Table
# 6. Create Security Group to allow port 22,80,443
# 7. Create a Network Interface with an ip in the Subnet that was created in step 4
# 8. Assign an elastic IP to the network interface created in step 7
# 9. Create Ubuntu server and install/enable apache2
#------------------------