provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

variable "port" {
  description = "The port that the app is running on."
  default     = 8080
  type        = number
}

output "alb_dns" {
  value       = aws_lb.example.dns_name
  description = "Load Balancer's domain name"
}

# ~ Security Groups ~

resource "aws_security_group" "example" {
  # security groups for EC2's, Allows traffic from a certain port from any ip address
  name = "example-security"

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "loadBalancer" {
  name = "alb-security"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# ~ Autoscaling Group ~

resource "aws_autoscaling_group" "example" {
  # specifies the config for the cluster of EC2's

  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns    = [aws_lb_target_group.target-group.arn]
  health_check_type    = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "example" {
  # specifies how to configure each EC2 instance in the auto scaling group
  image_id        = "ami-02f3416038bdb17fb"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.example.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.port} &
              EOF

  lifecycle {
    create_before_destroy = true # we need this for autoscalling groups
  }
}

# ~ Load Balancer ~

resource "aws_lb" "example" {
  name               = "load-balancer"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.loadBalancer.id]
}

resource "aws_lb_target_group" "target-group" {
  name     = "example-target-group"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = aws_lb_listener.example.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  # will return a 404 page if the request doesn't match one of the lister rules
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Can't find that Page Buddy"
      status_code  = 404
    }
  }
}

