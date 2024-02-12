
resource "aws_iam_user" "khh" {
  name = "Cluster-Master"
  path = "/"
  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_access_key" "khh" {
  user = aws_iam_user.khh.name
}

data "aws_iam_policy_document" "khh_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = [
          "ec2:Describe*",
          "eks:ListFargateProfiles",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:ListUpdates",
          "eks:AccessKubernetesApi",
          "eks:ListAddons",
          "eks:DescribeCluster",
          "eks:DescribeAddonVersions",
          "eks:ListClusters",
          "eks:ListIdentityProviderConfigs",
          "iam:ListRoles"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "khh_policy" {
  name   = "test"
  user   = aws_iam_user.khh.name
  policy = data.aws_iam_policy_document.khh_policy_doc.json
}


