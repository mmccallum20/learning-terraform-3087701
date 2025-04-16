# creating an Amazon Machine Image (AMI)

data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

# Retrieving information about the default Virtual Private Cloud (VPC) from AWS

data "aws_vpc" "default" {
  default = true
}

# Creating a blog VPC using a module (a container for specific resource configurations)

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# This autoscaling module will replace the original aws_instance (now deleted)

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.2.0"
  name = "blog"
  min_size = 1
  max_size = 2 
  
  # This is how you specify subnets within a autoscaling module 

  vpc_zone_identifier = module.blog_vpc.public_subnets
  health_check_type         = "EC2"

  image_id           = data.aws_ami.app_ami.id
  instance_type      = var.instance_type
  security_groups    = [module.blog_sg.security_group_id]

  initial_lifecycle_hooks = [
    {
      name                  = "ExampleStartupLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 60
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
    },
    {
      name                  = "ExampleTerminationLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 180
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
    }
  ]
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = module.autoscaling.this_autoscaling_group_id
  alb_target_group_arn   = aws_lb_target_group.blog_tg.arn
}


# Creating a Load Balancer using a module 

module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "blog-alb"
  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]

  # Creating a Security Group within our Load Balancer for security 

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  # Creating a listener within our load balancer to watch for traffic and direct it 
  # to a specific place 

  listeners = {
    alb_listener = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_ip"
      }
    }
  }

   target_groups = {
    ex_ip = {
      name                              = "blog-alb"
      protocol                          = "HTTP"
      port                              = 80
      target_type                       = "instance"
      create_attachment                 = true
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        healthy_threshold   = "3"
        interval            = "30"
        protocol            = "HTTP"
        matcher             = "200"
        timeout             = "3"
        path                = "/"
        unhealthy_threshold = "2"
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "Example"
  }
}

# Creating a security group, using a module  

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  vpc_id = module.blog_vpc.vpc_id
  name = "blog_new"


  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}


