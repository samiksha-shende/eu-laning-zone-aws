#resource "aws_organizations_policy" "eu_sovereignty" {
#  name        = "EU-Sovereignty-Guardrail"
  #description = "Blocks all regions except Frankfurt and Ireland."
  
  #content = <<CONTENT
#{
  #"Version": "2012-10-17",
  #"Statement": [
 #   {
     # "Sid": "DenyNonEU",
     # "Effect": "Deny",
      #"NotAction": ["iam:*", "organizations:*", "route53:*", "cloudfront:*"],
      #"Resource": "*",
      #"Condition": {
       #"StringNotLike": {
          #"aws:RequestedRegion": ["eu-central-1", "eu-west-1"]
 #      }
 #    }
 #  }
# ]
#}
#CONTENT
#}
