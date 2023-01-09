terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0"
    }
  }

}

provider "aws" {
  region = "eu-west-2"

}


resource "aws_vpc" "eks_prod_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "EKS prod vpc"
  }
}

resource "aws_internet_gateway" "eks_prod_igw" {
  vpc_id = aws_vpc.eks_prod_vpc.id

  tags = {
    name = "EKS prod IGW"
  }

}

resource "aws_subnet" "eks_prod_private_subnet_a" {
  vpc_id            = aws_vpc.eks_prod_vpc.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "eu-west-2a"

  tags = {
    name                               = "prod-private-subnet-eu-west-2a"
    "kubernetes.io/role/internal-elb"  = "1"     # required
    "kubernetes.io/cluster/ap-cluster" = "owned" # required this should include the name of the cluster

  }

}

resource "aws_subnet" "eks_prod_public_subnet_a" {
  vpc_id            = aws_vpc.eks_prod_vpc.id
  cidr_block        = "10.0.64.0/19"
  availability_zone = "eu-west-2a"

  tags = {
    name                               = "prod-public-subnet-eu-west-2a"
    "kubernetes.io/role/elb"           = "1"     # required
    "kubernetes.io/cluster/ap-cluster" = "owned" # required this should include the name of the cluster

  }

}


resource "aws_subnet" "eks_prod_public_subnet_b" {
  vpc_id            = aws_vpc.eks_prod_vpc.id
  cidr_block        = "10.0.96.0/19"
  availability_zone = "eu-west-2b"

  tags = {
    name                               = "prod-public-subnet-eu-west-2b"
    "kubernetes.io/role/elb"           = "1"     # required
    "kubernetes.io/cluster/ap-cluster" = "owned" # required this should include the name of the cluster

  }

}


resource "aws_subnet" "eks_prod_private_subnet_b" {
  vpc_id            = aws_vpc.eks_prod_vpc.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "eu-west-2b"

  tags = {
    name                               = "prod-private-subnet-eu-west-2b"
    "kubernetes.io/role/internal-elb"  = "1"     # required
    "kubernetes.io/cluster/ap-cluster" = "owned" # required this should include the name of the cluster

  }

}


resource "aws_eip" "eks_prod_eip" {
  vpc = true

  tags = {
    Name = "eks_prod_nat-eip"
  }

}

resource "aws_nat_gateway" "eks_prod_nat_gateway" {
  subnet_id     = aws_subnet.eks_prod_public_subnet_a.id
  allocation_id = aws_eip.eks_prod_eip.id

  tags = {
    name = "eks_prod_nat_gateway"
  }

  depends_on = [aws_internet_gateway.eks_prod_igw]
}

resource "aws_route_table" "eks_prod_private_rt" {
  vpc_id = aws_vpc.eks_prod_vpc.id

  route {
    nat_gateway_id = aws_nat_gateway.eks_prod_nat_gateway.id
    cidr_block     = "0.0.0.0/0"

  }
  tags = {
    Name = "EKS PRIVATE RT"
  }

}




resource "aws_route_table" "eks_prod_public_rt" {
  vpc_id = aws_vpc.eks_prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_prod_igw.id

  }
  tags = {
    Name = "EKS PUBLIC RT"
  }
}


resource "aws_route_table_association" "eks_prod_public_subnet_a" {
  route_table_id = aws_route_table.eks_prod_public_rt.id
  subnet_id      = aws_subnet.eks_prod_public_subnet_a.id

}

resource "aws_route_table_association" "eks_prod_public_subnet_b" {
  route_table_id = aws_route_table.eks_prod_public_rt.id
  subnet_id      = aws_subnet.eks_prod_public_subnet_b.id

}


resource "aws_route_table_association" "eks_prod_private_subnet_a" {
  route_table_id = aws_route_table.eks_prod_private_rt.id
  subnet_id      = aws_subnet.eks_prod_private_subnet_a.id

}

resource "aws_route_table_association" "eks_prod_private_subnet_b" {
  route_table_id = aws_route_table.eks_prod_private_rt.id
  subnet_id      = aws_subnet.eks_prod_private_subnet_b.id

}




resource "aws_iam_role" "eks_prod_cluster" {
  name = "eks-cluster-prod-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}



resource "aws_iam_role_policy_attachment" "eks-prod-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_prod_cluster.name
}


resource "aws_eks_cluster" "eks_prod_cluster" {
  name     = "eks_prod_cluster"
  role_arn = aws_iam_role.eks_prod_cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.eks_prod_public_subnet_a.id,
      aws_subnet.eks_prod_public_subnet_b.id,
      aws_subnet.eks_prod_private_subnet_a.id,
      aws_subnet.eks_prod_private_subnet_b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks-prod-cluster-AmazonEKSClusterPolicy]
}



################################################################

resource "aws_iam_role" "eks_cluster_prod_nodes" {
  name = "eks-prod-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-prod-nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_cluster_prod_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks-prod-nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cluster_prod_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks-prod-nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_cluster_prod_nodes.name
}

resource "aws_eks_node_group" "eks_cluster_prod_private_nodes" {
  cluster_name    = aws_eks_cluster.eks_prod_cluster.name
  node_group_name = "eks-custer-private-nodes"
  node_role_arn   = aws_iam_role.eks_cluster_prod_nodes.arn

  subnet_ids = [
    aws_subnet.eks_prod_private_subnet_a.id,
    aws_subnet.eks_prod_private_subnet_b.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  # taint {
  #   key    = "team"
  #   value  = "devops"
  #   effect = "NO_SCHEDULE"
  # }

  # launch_template {
  #   name    = aws_launch_template.eks-with-disks.name
  #   version = aws_launch_template.eks-with-disks.latest_version
  # }

  depends_on = [
    aws_iam_role_policy_attachment.eks-prod-nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-prod-nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-prod-nodes-AmazonEC2ContainerRegistryReadOnly,
  ]
}

# resource "aws_launch_template" "eks-with-disks" {
#   name = "eks-with-disks"

#   key_name = "local-provisioner"

#   block_device_mappings {
#     device_name = "/dev/xvdb"

#     ebs {
#       volume_size = 50
#       volume_type = "gp2"
#     }
#   }
# }


################################################################

# To manage permissions for your applications that you deploy in Kubernetes. 
# You can either attach policies to Kubernetes nodes directly. In that case, 
# every pod will get the same access to AWS resources. Or you can create 
# OpenID connect provider, which will allow granting IAM permissions based 
# on the service account used by the pod.


data "tls_certificate" "eks_prod_tlsc_cert" {
  url = aws_eks_cluster.eks_prod_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_prod_openid_connect_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_prod_tlsc_cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_prod_cluster.identity[0].oidc[0].issuer
}



################################ IAM TESTING ********************************

data "aws_iam_policy_document" "test_oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_prod_openid_connect_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:aws-test"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_prod_openid_connect_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "test_oidc" {
  assume_role_policy = data.aws_iam_policy_document.test_oidc_assume_role_policy.json
  name               = "test-oidc"
}

resource "aws_iam_policy" "test-policy" {
  name = "test-policy"

  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation"
      ]
      Effect   = "Allow"
      Resource = "arn:aws:s3:::*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.test_oidc.name
  policy_arn = aws_iam_policy.test-policy.arn
}

output "test_policy_arn" {
  value = aws_iam_role.test_oidc.arn
}



################################ EBSI-DRIVER


# data "tls_certificate" "prod_eks_tls" {
#   url = aws_eks_cluster.eks_prod_cluster.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "prod_eks_oidc" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.prod_eks_tls.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.eks_prod_cluster.identity[0].oidc[0].issuer
# }


# resource "aws_eks_addon" "csi_driver" {
#   cluster_name             = aws_eks_cluster.eks_prod_cluster.name
#   addon_name               = "aws-ebs-csi-driver"
#   addon_version            = "v1.11.4-eksbuild.1" #### Make 
#   service_account_role_arn = aws_iam_role.prod_eks_ebs_csi_driver.arn
# }


# data "aws_iam_policy_document" "prod_eks_csi" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_iam_openid_connect_provider.prod_eks_oidc.url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
#     }

#     principals {
#       identifiers = [aws_iam_openid_connect_provider.prod_eks_oidc.arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "prod_eks_ebs_csi_driver" {
#   assume_role_policy = data.aws_iam_policy_document.prod_eks_csi.json
#   name               = "eks-ebs-csi-driver"
# }

# resource "aws_iam_role_policy_attachment" "prod_amazon_ebs_csi_driver" {
#   role       = aws_iam_role.prod_eks_ebs_csi_driver.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }


################################################################




# Optional: only if you use your own KMS key to encrypt EBS volumes
# TODO: replace arn:aws:kms:us-east-1:424432388155:key/7a8ea545-e379-4ac5-8903-3f5ae22ea847 with your KMS key id arn!
# resource "aws_iam_policy" "prod_eks_ebs_csi_driver_kms" {
#   name = "KMS_Key_For_Encryption_On_EBS"

#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:CreateGrant",
#         "kms:ListGrants",
#         "kms:RevokeGrant"
#       ],
#       "Resource": ["arn:aws:kms:us-east-1:424432388155:key/7a8ea545-e379-4ac5-8903-3f5ae22ea847"],
#       "Condition": {
#         "Bool": {
#           "kms:GrantIsForAWSResource": "true"
#         }
#       }
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "kms:Encrypt",
#         "kms:Decrypt",
#         "kms:ReEncrypt*",
#         "kms:GenerateDataKey*",
#         "kms:DescribeKey"
#       ],
#       "Resource": ["arn:aws:kms:us-east-1:424432388155:key/7a8ea545-e379-4ac5-8903-3f5ae22ea847"]
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "amazon_ebs_csi_driver_kms" {
#   role       = aws_iam_role.prod_eks_ebs_csi_driver.name
#   policy_arn = aws_iam_policy.prod_eks_ebs_csi_driver_kms.ar


# data aws_iam_openid_connect_provider"" "prod_eks_oidc_provider" {
#     name

# }

# data "aws_iam_openid_connect_provider" "name" {
#     n

# }
