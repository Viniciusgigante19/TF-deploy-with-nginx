echo "Atualizando pacotes..."
sudo apt update

echo "Instalando Nginx..."
sudo apt install nginx -y

echo "Removendo configuração default..."
sudo rm -f /etc/nginx/sites-enabled/default

echo "Copiando arquivos do site..."
sudo cp -r website/* /usr/share/nginx/html/

echo "Copiando configuração personalizada..."
sudo cp nginx/site.conf /etc/nginx/sites-available/empresa

echo "Ativando virtual host..."
sudo ln -sf /etc/nginx/sites-available/empresa /etc/nginx/sites-enabled/

echo "Definindo permissões"
sudo chown -R www-data:www-data /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

echo "Habilitando Nginx no boot"
sudo systemctl enable nginx

echo "Reiniciando serviço"
sudo systemctl restart nginx

echo "Deploy concluído! Acesse: http://localhost"