provider "aws" {
  region = "us-east-2"
}

variable "port" {
  description = "The port that the app is running on."
  default     = 8080
  type        = number
}

output "public_url" {
  description = "Url used to reach the server."
  value       = "http://${aws_instance.example-instance.public_ip}:${var.port}"
}

resource "aws_instance" "example-instance" {
  ami           = "ami-02f3416038bdb17fb"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hi there!" > index.html
              nohup busybox httpd -f -p ${var.port} &
              EOF

  vpc_security_group_ids = [aws_security_group.instance-security-group.id]

  tags = {
    "Name" = "First-Book-Example"
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
