# Configure the AWS Provider
provider "aws" {
    region = "${var.region}"
    profile = "${var.aws_profile}"    
}

resource "aws_security_group" "server_sg" {
  name        = "code_server_sg"
  description = "Allow traffic from load balancer"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow HTTP over 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = ["${aws_security_group.lb_sg.id}"]
  }
  ingress {
    description = "allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = ["${aws_security_group.lb_sg.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Code Server SG"
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "load_balancer_sg"
  description = "Allow traffic from internet"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    description = "allow HTTP over 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = ["${aws_security_group.server_sg.id}"]
  }

  tags = {
    Name = "Load Balancer SG"
  }
}

# Application Load Balancer Target Group
resource "aws_lb_target_group" "code_server" {
  name     = "code-server-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${var.aws_vpc_id}"
  target_type = "instance"
  health_check {
    interval = 30
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 2
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    matcher = "200,302"
  }
}

# Application Load Balancer
resource "aws_lb" "code_server_lb" {
  name               = "code-server-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${var.subnet_id_1}", "${var.subnet_id_2}"]

  enable_deletion_protection = false

  tags = {
    Name = "Code Server ALB"
  }
}
# Application Load Balancer Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.code_server_lb.arn}"
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.code_server.arn}"
  }
}
# Application Load Balancer Listener Rule: Forward action
resource "aws_lb_listener_rule" "main_routing" {
  listener_arn = "${aws_lb_listener.front_end.arn}"
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.code_server.arn}"
  }

  condition {
    # host_header {
    #   values = ["my-service.*.terraform.io"]
    # }
    path_pattern {
      values = ["/"]
    }
  }
}
# Application Load Balancer Attachment
resource "aws_lb_target_group_attachment" "code_server_tg" {
  target_group_arn = "${aws_lb_target_group.code_server.arn}"
  target_id        = "${aws_instance.main_server.id}"
  port             = 8080
}

resource "aws_instance" "main_server" {
  ami = "${var.ami_id_amazon_linux}"
  instance_type = "${var.machine_type}"
  subnet_id = "${var.subnet_id_1}"
  vpc_security_group_ids = [ "${aws_security_group.server_sg.id}" ]
  key_name = "${var.ec2_ssh_key}"
  ebs_optimized   = false
  associate_public_ip_address = true
  root_block_device {
    volume_size = "20"
    encrypted = true
  }
  tags = {
    Name = "remote code server"
  }
    availability_zone = "${var.region}a"
}

resource "aws_ebs_volume" "vol_server" {
  availability_zone = "${var.region}a"
  size = "50"
  encrypted = true
  tags {
          Name = "Mount drive on code server"
    }
}

resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/xvdp"
  volume_id = "${aws_ebs_volume.vol_server.id}"
  instance_id = "${aws_instance.main_server.id}"
  force_detach = true
}

resource "null_resource" "server_provisioner" {
    provisioner "file" {
      source = "./README.md"
      destination = "~/README.md"
  }
  provisioner "remote-exec" {
    inline = [
        "echo \"--- Update packages ---\"",
        "sudo yum update -y",
        "echo \"--- Install Docker ---\"",
        "sudo yum install docker -y",
        "sudo usermod -aG docker ec2-user",
        "sudo service docker start",
        "echo \"--- Mounting EBS volume ---\"",
        "sudo mkdir /mnt/projects",
        "sudo mkfs.ext4 /dev/xvdp",
        "sudo mount /dev/xvdp /mnt/projects",
        "sudo chown -R ec2-user:ec2-user /mnt",
        "sudo mv ~/README.md /mnt/projects/",
    ]
  }
  connection {
    host = "${aws_instance.main_server.public_ip}"
    user = "ec2-user"
    private_key = "${file("~/.ssh/${var.ec2_ssh_key}.pem")}"
  }
}

output "server_output" {
  value = "${aws_instance.main_server.public_ip}"
  description = "Public IP address of newly-created EC2 instance"
}
output "load_balancer_output" {
  value = "${aws_lb.code_server_lb.dns_name}"
  description = "DNS name of public load balancer"
}