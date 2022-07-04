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

resource "aws_launch_configuration" "launch-config" {
  image_id        = "ami-02f3416038bdb17fb"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance-security-group.id]
  user_data       = <<-EOF
                        #!/bin/bash
                        echo "Hi there!" > index.html
                        nohup busybox httpd -f -p ${var.port} &
                        EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "book-autoscalerBoi" {
  launch_configuration = aws_launch_configuration.launch-config.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  min_size             = 2
  max_size             = 5

  tag {
    key                 = "Name"
    value               = "book-asg-example"
    propagate_at_launch = true
  }
}



resource "aws_security_group" "instance-security-group" {
  name = "book-example-security"

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
