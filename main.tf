provider "aws" {
  region = "us-east-1"  
}

resource "aws_instance" "flask_server" {
  ami           = "ami-0e86e20dae9224db8"  # Ubuntu 24.04 LTS in us-east-1 (check latest AMI via AWS Console)
  instance_type = "t2.micro"  
  key_name      = "my-ec2-key"  

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y docker.io git
    systemctl start docker
    systemctl enable docker
    git clone https://github.com/LuciusScipio/flask-docker-ec2.git /app  
    cd /app
    docker build -t flask-app .
    docker run -d -p 80:5000 flask-app
    EOF

  tags = {
    Name = "FlaskAppServer"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "allow_web_ssh"
  description = "Allow HTTP and SSH inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["197.211.59.79/32"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value = aws_instance.flask_server.public_ip
}