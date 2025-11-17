# server management group
resource "aws_iam_group" "sprints_server_management_group" {
  name = "server-management-group"
}

# database management group
resource "aws_iam_group" "sprints_database_management_group" {
  name = "database-management-group"
}

# user management group
resource "aws_iam_group" "sprints_user_management_group" {
  name = "user-management-group"
}

# ユーザー：テスト太郎
resource "aws_iam_user" "taro_test" {
  name = "test-taro"
}
## テスト太郎のグループ
resource "aws_iam_user_group_membership" "taro_test" {
  user = aws_iam_user.taro_test.name

  groups = [aws_iam_group.sprints_user_management_group.name]
}

# ユーザー：テスト次郎
resource "aws_iam_user" "jiro_test" {
  name = "test-jiro"
}
## テスト次郎の所属グループ
resource "aws_iam_user_group_membership" "jiro_test" {
  user = aws_iam_user.jiro_test.name

  groups = [aws_iam_group.sprints_server_management_group.name]
}

# ユーザー：テスト三郎
resource "aws_iam_user" "saburo_test" {
  name = "test-saburo"
}
## テスト三郎の所属グループ
resource "aws_iam_user_group_membership" "saburo_test" {
  user = aws_iam_user.saburo_test.name

  groups = [aws_iam_group.sprints_database_management_group.name]
}

# ユーザー：テスト四郎
resource "aws_iam_user" "shiro_test" {
  name = "test-shiro"
}
## テスト四郎の所属グループ
resource "aws_iam_user_group_membership" "shiro_test" {
  user = aws_iam_user.shiro_test.name

  groups = [
    aws_iam_group.sprints_server_management_group.name,
    aws_iam_group.sprints_database_management_group.name
  ]
}

# server-management-groupのポリシードキュメント
data "aws_iam_policy_document" "sprints_server_management" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances",
      "ec2:TerminateInstances",
      "ec2:Describe*",
      "ec2:ModifyInstanceAttribute"
    ]
    resources = [
      "arn:aws:ec2:${var.region}:${var.account_id}:instance/*"
    ]
  }
}
## server-managementのポリシードキュメントをポリシーにアタッチ
resource "aws_iam_policy" "sprints_server_management" {
  name   = "server-management-policy"
  policy = data.aws_iam_policy_document.sprints_server_management.json
}
## server-management-policyをserver-management-groupにアタッチ
resource "aws_iam_group_policy_attachment" "sprints_server_management" {
  group      = aws_iam_group.sprints_server_management_group.name
  policy_arn = aws_iam_policy.sprints_server_management.arn
}

# database-management-groupのポリシードキュメント
data "aws_iam_policy_document" "sprints_database_management" {
  statement {
    effect = "Allow"
    actions = [
      "rds:StartDBInstance",
      "rds:StopDBInstance",
      "rds:RebootDBInstance",
      "rds:DeleteDBInstance",
      "rds:ModifyDBInstance",
      "rds:DescribeDBInstances",
      "rds:CreateDBSnapshot"
    ]
    resources = [
      "arn:aws:rds:${var.region}:${var.account_id}:db:*"
    ]
  }
}
## database-managementのポリシードキュメントをポリシーにアタッチ
resource "aws_iam_policy" "sprints_database_management" {
  name   = "database-management-policy"
  policy = data.aws_iam_policy_document.sprints_database_management.json
}
## database-management-policyをdatabase-management-groupにアタッチ
resource "aws_iam_group_policy_attachment" "sprints_database_management" {
  group      = aws_iam_group.sprints_database_management_group.name
  policy_arn = aws_iam_policy.sprints_database_management.arn
}

# user-management-groupのポリシードキュメント
data "aws_iam_policy_document" "sprints_user_management" {
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateUser",
      "iam:DeleteUser",
      "iam:ListUsers",
      "iam:UpdateUser"
    ]
    resources = [
      "arn:aws:iam::${var.account_id}:user/*"
    ]
  }
}
## user-managementのポリシードキュメントをポリシーにアタッチ
resource "aws_iam_policy" "sprints_user_management" {
  name   = "user-management-policy"
  policy = data.aws_iam_policy_document.sprints_user_management.json
}
## user-managementポリシーをuser-management-groupにアタッチ
resource "aws_iam_group_policy_attachment" "sprints_user_management" {
  group      = aws_iam_group.sprints_user_management_group.name
  policy_arn = aws_iam_policy.sprints_user_management.arn
}
