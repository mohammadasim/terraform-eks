# Create Security group for public ALB
resource "aws_security_group" "public_alb" {
    name             = "public_alb_sg"
    description      = "Allow inbound traffic on https only"
    vpc_id           = module.vpc.vpc_id
    ingress {
        description        = "Allow TLS from world"
        from_port          = 443
        to_port            = 443
        protocol           = "tcp"
        cidr_blocks        = ["0.0.0.0/0"]
    }
    egress{
        from_port          = 0
        to_port            = 0
        protocol           = -1
        cidr_blocks        = ["0.0.0.0/0"]
    }
}

# Create Security group for private ALB
resource "aws_security_group" "private_alb" {
    name             = "private_alb_sg"
    description      = "Allow inbound traffic on https only"
    vpc_id           = module.vpc.vpc_id
    ingress {
        description        = "Allow TLS from secure locations"
        from_port          = 443
        to_port            = 443
        protocol           = "tcp"
        cidr_blocks        = ["10.10.0.0/16"]   # Dummy CIDR for a vpn or ZTNA VPC
    }
    egress{
        from_port          = 0
        to_port            = 0
        protocol           = -1
        cidr_blocks        = ["0.0.0.0/0"]
    }
}

# Create Security group for EKS Nodes
resource "aws_security_group" "base_security_group" {
    name            = "node_base_sg"
    description     = "Allow traffic only from private and public alb sg"
    vpc_id          = module.vpc.vpc_id
    ingress {
        description   = "Allow http traffic from secure ALB only"
        from_port     = 80
        to_port       = 80
        protocol      = "tcp"
        security_groups = [aws_security_group.public_alb.id, aws_security_group.private_alb.id]
    }
}