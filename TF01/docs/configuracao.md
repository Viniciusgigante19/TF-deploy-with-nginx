# Documentação de Configuração - Projeto Arvus

Esta documentação detalha a arquitetura de implantação e a lógica por trás dos procedimentos operacionais padrão definidos no projeto.

---

## 1. Arquitetura de Ambiente

O projeto utiliza o **WSL2 (Windows Subsystem for Linux)** com a distribuição **Ubuntu**.

sejam idênticos a um servidor de produção real (como AWS ou DigitalOcean).

**A escolha do `$HOME`**  
Instruímos o uso do diretório `/home/usuario` em vez de `/mnt/c/` para evitar:
 
- Conflitos de permissão no Nginx

---

## 2. Fluxo de Instalação (Pipeline Manual)

O processo de configuração foi dividido em etapas lógicas para garantir a integridade do servidor:

### A. Preparação de Permissões (`chmod +x`)

Arquivos clonados via Git frequentemente perdem o bit de execução por questões de segurança.  

O comando `chmod +x` é obrigatório para transformar o arquivo de texto `install.sh` em um binário interpretável pelo Kernel.

### B. Elevação de Privilégios (`sudo`)

A configuração de servidores web exige acesso a áreas protegidas do sistema operacional:

- `/etc/nginx/` – Onde residem as definições de portas (80) e hosts  
- `/var/www/html/` – Onde os arquivos estáticos são servidos  

O uso do `sudo` no script `install.sh` permite a escrita nessas pastas e o reinício do serviço via `systemctl` ou `service`.

---

## 3. Estrutura do Servidor Nginx

O script de instalação foi projetado para:

- Limpar o diretório padrão do Nginx para evitar conflitos com a "página de boas-vindas" do Ubuntu  
- Mover os arquivos otimizados da pasta `./TF01/website/` para a raiz do servidor  
- Aplicar o arquivo `./TF01/nginx/site.conf` para definir como o servidor deve tratar erros 404 e rotas de serviços

---

## 4. Ordem de Execução Recomendada

```bash
wsl -d ubuntu          # Acesso
cd $HOME               # Estabilidade de sistema de arquivos
git clone <repo_url>   # Obtenção do código
chmod +x install.sh    # Liberação do script
sudo ./install.sh      # Implantação



# Explicação - site.conf (Nginx)

## Configuração Básica
```nginx
listen 80;
server_name localhost;
root /usr/share/nginx/html;
index index.html;
```
Escuta na porta 80, serve arquivos de `/usr/share/nginx/html`, padrão é `index.html`.

## Logs e Segurança
```nginx
access_log /var/log/nginx/empresa_access.log;
error_log /var/log/nginx/empresa_error.log;
autoindex off;
```
Registra acessos e erros; `autoindex off` impede listagem de diretórios.

## Erros HTTP
```nginx
error_page 404 /404.html;
error_page 500 502 503 504 /50x.html;
```
Mapeia 404 e erros 5xx para páginas personalizadas.

## Cache de Imagens
```nginx
location /images/ {
    expires 7d;
    add_header Cache-Control "public";
}
```
Imagens em `/images/` ficam em cache por 7 dias.



# Explicação - install.sh

## Objetivo
Script de automação para instalar Nginx, configurar site estático e fazer deploy automático.

## Definição de Diretório Base
```bash
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
```
Define caminho relativo ao script, permitindo executar de qualquer lugar.

## Atualização e Instalação
```bash
sudo apt update
sudo apt install nginx -y
```
Atualiza repositórios e instala Nginx.

## Ativação e Configuração
```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo cp "$BASE_DIR/nginx/site.conf" /etc/nginx/sites-available/empresa
sudo ln -sf /etc/nginx/sites-available/empresa /etc/nginx/sites-enabled/
```
Remove config padrão, copia arquivo personalizado e ativa como virtual host.

## Deploy de Arquivos
```bash
sudo cp -r "$BASE_DIR/website/"* /usr/share/nginx/html/
```
Copia todos os arquivos do site para o diretório raiz do Nginx.

## Permissões e Habilitação
```bash
sudo chown -R www-data:www-data /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html
sudo systemctl enable nginx
sudo systemctl restart nginx
```
Define proprietário como `www-data`, permissões 755, ativa no boot e reinicia serviço.

## Fluxo
1. Define caminho do projeto
2. Instala Nginx
3. Copia site e configuração
4. Ajusta permissões
5. Ativa serviço
6. Deploy completo em uma execução
