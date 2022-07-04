provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example-instance" {
  ami           = "ami-02f3416038bdb17fb"
  instance_type = "t2.micro"
  tags = {
    "Name" = "First-Book-Example"
  }
}
