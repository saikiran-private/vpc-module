resource "aws_vpc" "tier-3-vpc" {
  cidr_block = var.vpc-cidr

    tags = {
    Name = "3-tier-vpc"
  }
}



resource "aws_subnet" "public-subnet-az1" {
  depends_on = [ aws_vpc.tier-3-vpc ]
  vpc_id     = aws_vpc.tier-3-vpc.id
  cidr_block = var.cidr-public-az1
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "public-subnet-az1"
  }
}


resource "aws_subnet" "public-subnet-az2" {
  vpc_id     = aws_vpc.tier-3-vpc.id
  cidr_block = var.cidr-public-az2
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "public-subnet-az2"
  }
}

resource "aws_subnet" "private-subnet-az1" {
  vpc_id     = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "private-subnet-az1"
  }
}

resource "aws_subnet" "private-subnet-az2" {
  vpc_id     = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.30.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private-subnet-az2"
  }
}


resource "aws_subnet" "private-db-subnet-az1" {
  vpc_id     = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.40.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "private-db-subnet-az1"
  }
}

resource "aws_subnet" "private-db-subnet-az2" {
  vpc_id     = aws_vpc.tier-3-vpc.id
  cidr_block = "10.0.50.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private-db-subnet-az2"
  }
}


resource "aws_internet_gateway" "tier-3-IGW" {
  vpc_id = aws_vpc.tier-3-vpc.id

  tags = {
    Name = "3-Tier-IGW"
  }
}

resource "aws_route_table" "tier-3-RT-IGW" {
  vpc_id = aws_vpc.tier-3-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tier-3-IGW.id
  }

  tags = {
    Name = "3-Tier-RT-IGW"
  }
}


resource "aws_route_table_association" "RTA-3tier-IGW-Public1" {
  subnet_id      = aws_subnet.public-subnet-az1.id
  route_table_id = aws_route_table.tier-3-RT-IGW.id
}


resource "aws_eip" "eip-NAT1-public" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "Nat1-public-facing" {
  allocation_id = aws_eip.eip-NAT1-public.id
  subnet_id     = aws_subnet.public-subnet-az1.id

  tags = {
    Name = "Nat1-public-facing"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.tier-3-IGW]
}

resource "aws_route_table" "Nat1-RT-private" {
  vpc_id = aws_vpc.tier-3-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.Nat1-public-facing.id
  }

  tags = {
    Name = "Nat1-RT-private"
  }
}

resource "aws_route_table_association" "RTA-nat1-privateaz1" {
  subnet_id      = aws_subnet.private-subnet-az1.id
  route_table_id = aws_route_table.Nat1-RT-private.id
}

resource "aws_eip" "eip-NAT2-public" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "Nat2-public-facing" {
  allocation_id = aws_eip.eip-NAT2-public.id
  subnet_id     = aws_subnet.public-subnet-az2.id

  tags = {
    Name = "Nat2-public-facing"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.tier-3-IGW]
}

resource "aws_route_table" "Nat2-RT-private" {
  vpc_id = aws_vpc.tier-3-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.Nat2-public-facing.id
  }

  tags = {
    Name = "Nat2-RT-private"
  }
}

resource "aws_route_table_association" "RTA-nat2-privateaz2" {
  subnet_id      = aws_subnet.private-subnet-az2.id
  route_table_id = aws_route_table.Nat2-RT-private.id
}
