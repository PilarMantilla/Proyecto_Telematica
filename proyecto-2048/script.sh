#!/bin/bash

# Definir variables para la ruta de la llave y la ruta del proyecto
KEY_PATH="./llave_mi"

# Inicializar Terraform (en la misma carpeta del script)
terraform init

# Aplicar los recursos automáticamente
terraform apply -auto-approve

# Esperar unos segundos para que la máquina termine de iniciar
echo "Esperando a que la máquina virtual esté disponible..."
sleep 15

# Obtener la IP pública generada por Terraform
IP=$(terraform output -raw public_ip)

# Mostrar la IP obtenida
echo "IP pública de la instancia: $IP"

# Copiar el Dockerfile a la instancia
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no ./docker/Dockerfile ec2-user@"$IP":~

# Conectarse a la instancia para instalar Docker, clonar el juego y ejecutarlo
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ec2-user@"$IP" << 'EOF'
  sudo yum update -y
  sudo yum install -y docker git
  sudo systemctl start docker
  sudo systemctl enable docker
  git clone https://github.com/gabrielecirulli/2048.git
  cd 2048

  echo -e "FROM nginx:alpine\nCOPY . /usr/share/nginx/html\nEXPOSE 80\nCMD [\"nginx\", \"-g\", \"daemon off;\"]" > Dockerfile

  sudo docker build -t juego-2048 .
  sudo docker run -d -p 80:80 juego-2048
EOF

# Mostrar URL final
echo "La aplicación 2048 está disponible en: http://$IP"

