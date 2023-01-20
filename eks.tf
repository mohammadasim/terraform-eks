locals {
  name            = "eks-cluster"
  cluster_version = "1.24"
  tags = {
    Project = "eks-terraform"
  }
}


data "aws_caller_identity" "current" {}
module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name           = "eks-key"
  create_private_key = true
}

resource "aws_iam_policy" "additional" {
  name        = "${local.name}-additional"
  description = "Additional node policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    cluster-autoscaler = {
      most_recent = true
    }
    load-balancer-controller = {
      most_recent = true
    }
    external-dns = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets

  # Self managed node groups will not automatically create the aws-auth configmap so we need to
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
        userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        username = "admin"
        groups = ["system.masters"]
    }
  ]
  create_iam_role = false
  iam_role_arn = aws_iam_role.node-group-role.arn
  node_security_group_id = aws_security_group.base_security_group.id
  self_managed_node_group_defaults = {
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${local.name}" : "owned",
    }
  }

# For each az we deploy an individual node-group
# All node groups use bottlerocket ami
  self_managed_node_groups = {

    node-group_a = {
      name            = "self-mng-node-group-a"
      platform        = "bottlerocket"
      ami_id          = data.aws_ami.eks_default_bottlerocket.id
      key_name        = module.key_pair.key_pair_name
      use_name_prefix = false

      subnet_ids = module.vpc.private_subnets[0]

      min_size     = 1
      max_size     = 7
      desired_size = 1

      bootstrap_extra_args =  <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false
        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true
        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT

      instance_type = "m6i.large"

      launch_template_name            = "self-managed-node-group-a"
      launch_template_use_name_prefix = false
      launch_template_description     = "Self managed node group a launch template"

      ebs_optimized     = true
      enable_monitoring = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 75
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }
      timeouts = {
        create = "80m"
        update = "80m"
        delete = "80m"
      }

      tags = {
        ExtraTag = "Self managed node group a"
      }
    }
    node-group_b = {
      name            = "self-mng-node-group-b"
      platform        = "bottlerocket"
      ami_id          = data.aws_ami.eks_default_bottlerocket.id
      key_name        = module.key_pair.key_pair_name
      use_name_prefix = false

      subnet_ids = module.vpc.private_subnets[1]

      min_size     = 1
      max_size     = 7
      desired_size = 1

      bootstrap_extra_args =  <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false
        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true
        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT

      instance_type = "m6i.large"

      launch_template_name            = "self-managed-ex-b"
      launch_template_use_name_prefix = false
      launch_template_description     = "Self managed node group b launch template"

      ebs_optimized     = true
      enable_monitoring = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 75
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }
      timeouts = {
        create = "80m"
        update = "80m"
        delete = "80m"
      }

      tags = {
        ExtraTag = "Self managed node group b"
      }
    }
    node-group-c = {
      name            = "self-mng-node-group-c"
      platform        = "bottlerocket"
      ami_id          = data.aws_ami.eks_default_bottlerocket.id
      key_name        = module.key_pair.key_pair_name
      use_name_prefix = false

      subnet_ids = module.vpc.private_subnets[2]

      min_size     = 1
      max_size     = 7
      desired_size = 1

      bootstrap_extra_args =  <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false
        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true
        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT

      instance_type = "m6i.large"

      launch_template_name            = "self-managed-ex-c"
      launch_template_use_name_prefix = false
      launch_template_description     = "Self managed node group c launch template"

      ebs_optimized     = true
      enable_monitoring = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 75
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }
      timeouts = {
        create = "80m"
        update = "80m"
        delete = "80m"
      }

      tags = {
        ExtraTag = "Self managed node group c"
      }
    }
  }

  tags = local.tags
}

# Get the latest Bottlerocket AMI
data "aws_ami" "eks_default_bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${local.cluster_version}-x86_64-*"]
  }
}

# Create KMS key to encrypt the EKS volumes
module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.1"

  description = "Customer managed key to encrypt EKS managed node group volumes"

  # Policy
  key_administrators = [
    data.aws_caller_identity.current.arn
  ]
  key_service_users = [
    # required for the ASG to manage encrypted volumes for nodes
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    aws_iam_role.node-group-role.arn,
  ]

  # Aliases
  aliases = ["eks/${local.name}/ebs"]

  tags = local.tags
}

# Create IAM role for Node groups
resource "aws_iam_role" "node-group-role" {
  name          = "node-group-iam-role"
  assume_role_policy = jsonencode ({
    Version = "2012-10-17"
    statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}
