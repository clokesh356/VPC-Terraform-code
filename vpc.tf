#.aws/credentials/config/region(it picks region)
data "aws_availability_zones" "available" {
  state = "available"
}
# create vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name      = "stage-vpc"
    Terraform = "True"
  }
}
# create igw and attach to vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "stage-igw"
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

resource "aws_subnet" "public" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.pubc_cidr, count.index)
  map_public_ip_on_launch = "true"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "stage--public-${count.index + 1}-subnet"
  }
}
resource "aws_subnet" "private" {
  count      = length(data.aws_availability_zones.available.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.private_cidr, count.index)
  # map_public_ip_on_launch = "true"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "stage--private-${count.index + 1}-subnet"
  }
}
resource "aws_subnet" "data" {
  count      = length(data.aws_availability_zones.available.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.data_cidr, count.index)
  # map_public_ip_on_launch = "true"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "stage--data-${count.index + 1}-subnet"
  }
}
#we are having issue with the cidr range
#az
#pub[0].......10.1.0.0/24
#pub[1].........10.1.1.0/24
#creating nat-gw
resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "stage-EIP"
  }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "stage-Nat-Gw"
  }
  depends_on = [
    aws_eip.eip
  ]
}
#route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "stage-public-route"
  }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "stage-private-route"
  }
}
#association route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "data" {
  count          = length(aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.data[*].id, count.index)
  route_table_id = aws_route_table.private.id
}