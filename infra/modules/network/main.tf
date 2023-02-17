resource "aws_vpc" "self" {
  cidr_block  = var.cidr_block
  tags        = merge({
    "Name" = var.network_name
  }, var.tags)
}

resource "aws_internet_gateway" "self" {
  vpc_id  = aws_vpc.self.id
  tags    = merge({
    "Name" = "${var.network_name}-main"
  }, var.tags)
}

resource "aws_route_table" "public" {
  vpc_id  = aws_vpc.self.id
  tags    = merge({
    "Name" = "${var.network_name}-public-routes"
  }, var.tags)

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.self.id
  }
}

# Public IPs

resource "aws_eip" "self" {
  count = length(var.availability_zones)
  vpc   = true

  depends_on = [aws_internet_gateway.self]
}

# Public subnets and routing

resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.self.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = local.subnet_ips[count.index]
  tags              = merge({
    "Name" = "${var.network_name}-public-subnet-${var.availability_zones[count.index]}"
  },
  {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }, var.tags)
}

resource "aws_nat_gateway" "self" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.self[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge({
    "Name" = "${var.network_name}-nat-gateway-${var.availability_zones[count.index]}"
  }, var.tags)
}

resource "aws_route_table_association" "public" {
  count           = length(var.availability_zones)
  subnet_id       = aws_subnet.public[count.index].id
  route_table_id  = aws_route_table.public.id
}

# Private subnets and routing

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.self.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = local.subnet_ips[length(var.availability_zones) + count.index]
  tags              = merge({
    "Name" = "${var.network_name}-private-subnet-${var.availability_zones[count.index]}"
  },
  {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }, var.tags)
}

resource "aws_route_table" "private" {
  count   = length(var.availability_zones)
  vpc_id  = aws_vpc.self.id
  tags    = merge({
    "Name" = "${var.network_name}-private-routes"
  }, var.tags)

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.self[count.index].id
  }
}

resource "aws_route_table_association" "private" {
  count           = length(var.availability_zones)
  subnet_id       = aws_subnet.private[count.index].id
  route_table_id  = aws_route_table.private[count.index].id
}

# Firewall rules

resource "aws_security_group" "self" {
  vpc_id  = aws_vpc.self.id
  tags    = merge({
    "Name" = "${var.network_name}-firewall"
  }, var.tags)

  # we don't need to specify separate ingress rules for our web app running
  # on Fargate as the ALB ingress controller does all of that work for us
  ingress {
    from_port = 0
    to_port = 0
    protocol = "all"
    cidr_blocks = [aws_vpc.self.cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
