variable "region" {
 description = "AWS region"
 type = string
 default = "us-east-1"
}

#Proveerdor AWS
provider "aws"{
 region = var.region
}

#VPC
resource "aws_vpc" "main_vpc" {
 cidr_block = "10.0.0.0/16"
 enable_dns_hostnames = true
 tags = {
  Name = "MainVPC"
 }
}

variable "availability_zone" {
  description = "Zona de disponibilidad para la subred"
  type        = string
  default     = "us-east-1a" # o la zona que tú quieras usar
}

#Subred publica
resource "aws_subnet" "public_subnet" {
 vpc_id = aws_vpc.main_vpc.id
 cidr_block = "10.0.1.0/24"
 availability_zone = var.availability_zone
 map_public_ip_on_launch = true

 tags = {
  Name = "PublicSubnet"
 }
}

#Gateway de Internet
resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.main_vpc.id
 tags = {
  Name = "MainIGW"
 }
}

#Tabla de ruteo
resource "aws_route_table" "route_table" {
 vpc_id = aws_vpc.main_vpc.id

 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
 }

 tags = {
  Name = "MainRouteTable"
 }
}

#Asociacion de ruta a subred
resource "aws_route_table_association" "rta" {
 subnet_id = aws_subnet.public_subnet.id
 route_table_id = aws_route_table.route_table.id
}

#Grupo de seguridad
resource "aws_security_group" "web_sg" {
 name = "web_sg"
 description = "Allow SSH and HTTP"
 vpc_id = aws_vpc.main_vpc.id

  ingress {
   description = "SSH"
   from_port = 22
   to_port = 22
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
   description = "HTTP"
   from_port = 80
   to_port = 80
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
}

  egress {
   description = "All traffic out"
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
}
  tags = {
   Name = "WebSG"
 }
}

#Clave SSH
resource "aws_key_pair" "llave_mi" {
 key_name = "llave_mi"
 public_key = file("${path.module}/llave_mi.pub")
}

variable "ami_id" {
  description = "ID de la Amazon Machine Image (AMI) que usará la instancia EC2"
  type        = string
  default     = "ami-0c02fb55956c7d316" # reemplaza por el ID real de la AMI
}

#Instancia EC2
resource "aws_instance" "web_server" {
 ami = var.ami_id
 instance_type = "t3.large"
 subnet_id = aws_subnet.public_subnet.id
 vpc_security_group_ids = [aws_security_group.web_sg.id]
 key_name = aws_key_pair.llave_mi.key_name

 root_block_device {
  volume_size = 12
  volume_type = "gp2"
}

user_data = file("${path.module}/script.sh")

 tags = {
  Name = "UbuntuWebServer"
 }
}

output "public_ip" {
  description = "La IP pública de la instancia EC2"
  value       = aws_instance.web_server.public_ip
}
