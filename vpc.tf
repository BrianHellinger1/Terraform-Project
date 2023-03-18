#creating a VPC
resource "aws_vpc" "week22-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "LUweek22vpc"
  }
}

#creating internet gateway
resource "aws_internet_gateway" "Week22-Gateway" {
  vpc_id = aws_vpc.week22-vpc.id

  tags = {
    Name = "Brians-Internet-Gateway"
  }
}

#creating elastic IP address
resource "aws_eip" "Week22-Elastic-IP" {
  vpc = true
}

#creating NAT gateway
resource "aws_nat_gateway" "Week22-NAT-Gateway" {
  allocation_id = aws_eip.Week22-Elastic-IP.id
  subnet_id     = aws_subnet.public-subnet2.id
}

#creating NAT route
resource "aws_route_table" "Week22-Route-two" {
  vpc_id = aws_vpc.week22-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Week22-NAT-Gateway.id
  }

  tags = {
    Name = "Brians-Week22-Network-Address-Route"
  }
}

#creating public subnet
resource "aws_subnet" "public-subnet1" {
  vpc_id                  = aws_vpc.week22-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "brians-public-subnet1"
  }
}

#creating public subnet
resource "aws_subnet" "public-subnet2" {
  vpc_id                  = aws_vpc.week22-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "brians-public-subnet2"
  }
}

#creating private subnet
resource "aws_subnet" "private-subnet1" {
  vpc_id                  = aws_vpc.week22-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "brians-private-subnet1"
  }
}

#creating private subnet
resource "aws_subnet" "private-subnet2" {
  vpc_id                  = aws_vpc.week22-vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "brians-private-subnet2"
  }
}

#creating subnet group
resource "aws_db_subnet_group" "brians-week22-subgroup" {
  name       = "brians-week22-subgroup"
  subnet_ids = [aws_subnet.private-subnet1.id, aws_subnet.private-subnet2.id]
  tags = {
    Name = "Brians data base subnet group"
  }
}

#creating route table association
resource "aws_route_table_association" "Week22-Route-two-1" {
  subnet_id      = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.Week22-Route-two.id
}
resource "aws_route_table_association" "Week22-Route-two-2" {
  subnet_id      = aws_subnet.private-subnet2.id
  route_table_id = aws_route_table.Week22-Route-two.id
}

#creating a security group
resource "aws_security_group" "Brians-sg" {
  name        = "Brians-sg"
  description = "security group for load balancer"
  vpc_id      = aws_vpc.week22-vpc.id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#creating a load balancer
resource "aws_lb" "Brians-lb" {
  name               = "Brians-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
  security_groups    = [aws_security_group.Brians-sg.id]
}

#creating load balancer security group
resource "aws_lb_target_group" "Brians-lb-tg" {
  name     = "week22targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.week22-vpc.id

  depends_on = [aws_vpc.week22-vpc]
}

#creating load balancer target group
resource "aws_lb_target_group_attachment" "Brians-target-group1" {
  target_group_arn = aws_lb_target_group.Brians-lb-tg.arn
  target_id        = aws_instance.Brians-web-tier1.id
  port             = 80

  depends_on = [aws_instance.Brians-web-tier1]
}
#creating load balancer target group
resource "aws_lb_target_group_attachment" "Brians-target-group2" {
  target_group_arn = aws_lb_target_group.Brians-lb-tg.arn
  target_id        = aws_instance.Brians-web-tier2.id
  port             = 80

  depends_on = [aws_instance.Brians-web-tier2]
}
#creating load balancer listener
resource "aws_lb_listener" "Brians-listener" {
  load_balancer_arn = aws_lb.Brians-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Brians-lb-tg.arn
  }
}

#creating route table
resource "aws_route_table" "Brians-Web-Tier" {
  tags = {
    Name = "Brians-Web-Tier"
  }
  vpc_id = aws_vpc.week22-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Week22-Gateway.id
  }
}

#creating route table association
resource "aws_route_table_association" "Week22-web-tier1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.Brians-Web-Tier.id
}

#creating route table association
resource "aws_route_table_association" "Week22-web-tier2" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.Brians-Web-Tier.id
}

#creating route table
resource "aws_route_table" "Week22-DataBase-Tier" {
  tags = {
    Name = "DataBase-Tier"
  }
  vpc_id = aws_vpc.week22-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Week22-Gateway.id
  }
}

#creating public security group
resource "aws_security_group" "Week22-Public-SG-DB" {
  name        = "Week22-Public-SG-DB"
  description = "web and SSH allowed"
  vpc_id      = aws_vpc.week22-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
