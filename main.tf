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

resource "aws_autoscaling_group" "example" {
  # specifies the config for the cluster of EC2's

  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

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
