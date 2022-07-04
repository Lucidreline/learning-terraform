provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example-instance" {
  ami           = "ami-02f3416038bdb17fb"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hi there!" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  vpc_security_group_ids = [aws_security_group.instance-security-group.id]

  tags = {
    "Name" = "First-Book-Example"
  }
}

resource "aws_security_group" "instance-security-group" {
  name = "book-example-security"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
