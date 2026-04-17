# 🛡️ Proyecto 08 — Implementación y Monitoreo Automatizado de Honeypots

**Grupo:** Oscorp  
**Integrantes:** López, Santiago — Morato, Elizabeth  
**Carrera:** Tecnicatura en Programación  
**Año:** 2026

---

## 📌 Descripción del Proyecto

Este proyecto implementa un sistema **completamente automatizado** de monitoreo de honeypots capaz de capturar, procesar, almacenar y visualizar eventos de intrusión en tiempo real, sin intervención manual.

El sistema utiliza el honeypot **Cowrie** para simular un servidor SSH vulnerable, **n8n** para automatizar el procesamiento de logs cada 1 minuto, **PostgreSQL** para almacenamiento estructurado, **ELK Stack** (Elasticsearch + Kibana) para análisis y visualización, y **Telegram** para alertas automáticas en tiempo real.

---

## 🏗️ Arquitectura del Sistema

```
Atacante
    ↓
Honeypot Cowrie (puerto 2222)
    ↓
Logs JSON (cowrie.json) — escritura automática
    ↓
n8n (Schedule Trigger — cada 1 minuto)
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

| Herramienta     | Versión  | Función                              |
|-----------------|----------|--------------------------------------|
| Docker          | 24+      | Contenedorización del entorno        |
| Cowrie          | 2.9+     | Honeypot SSH de media interacción    |
| PostgreSQL      | 16       | Base de datos relacional             |
| n8n             | 1.x      | Automatización de flujos (SOAR-lite) |
| Elasticsearch   | 8.13.0   | Motor de búsqueda y análisis         |
| Kibana          | 8.13.0   | Visualización de datos               |
| Python          | 3.11+    | Scripts de análisis de logs          |
| Telegram Bot    | API v6+  | Alertas automáticas en tiempo real   |

---

## ✅ Requisitos Previos

Antes de comenzar, asegurate de tener instalado:

- **Docker Desktop** — https://www.docker.com/products/docker-desktop
- **Git** — https://git-scm.com/download/win
- **Python 3.11+** — https://www.python.org/downloads/
- **DBeaver Community** (opcional) — https://dbeaver.io/download/

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

Desde la carpeta `docker/` ejecutar:

```bash
cd docker
docker-compose up -d
```

Este comando descarga automáticamente todas las imágenes y levanta los contenedores:

| Contenedor      | Imagen                  | Puerto |
|-----------------|-------------------------|--------|
| friendly_kalam  | cowrie/cowrie           | 2222   |
| db-honeypot     | postgres                | 5433   |
| n8n             | n8nio/n8n               | 5678   |
| elasticsearch   | elasticsearch:8.13.0    | 9200   |
| kibana          | kibana:8.13.0           | 5601   |

### Paso 3 — Verificar que todos los contenedores estén activos

```bash
docker ps
```

Deberías ver los 5 contenedores con estado `Up`.

### Paso 4 — Crear la base de datos

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

### Paso 5 — Verificar Elasticsearch y Kibana

- Elasticsearch: http://localhost:9200 — debe mostrar JSON con info del cluster
- Kibana: http://localhost:5601 — debe mostrar el panel principal

---

## 🔧 Configuración de n8n

### Acceder a n8n

```
http://localhost:5678
```

Crear una cuenta con cualquier email y contraseña (es local, no necesita ser real).

### Importar el workflow

1. En n8n ir a **Workflows**
2. Hacer clic en el menú **···**
3. Seleccionar **Import from file**
4. Seleccionar el archivo `scripts/workflow_honeypot.json`

### Configurar las credenciales

El workflow necesita tres credenciales. Configurarlas dentro de n8n en cada nodo correspondiente:

**PostgreSQL:**

| Campo    | Valor                  |
|----------|------------------------|
| Host     | host.docker.internal   |
| Port     | 5433                   |
| Database | honeypot               |
| User     | admin                  |
| Password | admin                  |

**Elasticsearch:**

| Campo    | Valor                           |
|----------|---------------------------------|
| Base URL | http://host.docker.internal:9200 |

**Telegram** (ver sección completa abajo):

| Campo        | Valor                          |
|--------------|--------------------------------|
| Access Token | El token de tu bot personal    |
| Chat ID      | Tu Chat ID personal            |

---

## 📲 Configuración de Alertas por Telegram

Cada integrante debe crear su propio bot de Telegram. Las alertas llegarán al celular del operador configurado.

### Paso 1 — Crear el bot con BotFather

1. Abrir Telegram y buscar **@BotFather**
2. Escribir `/newbot`
3. Ingresar un nombre para el bot, por ejemplo: `Honeypot Alertas`
4. Ingresar un username que termine en `bot`, por ejemplo: `honeypot_oscorp_bot`
5. BotFather devuelve un **token** con este formato:
   ```
   1234567890:AAHdqTcvCH1vGBJ29bqsj-VB0cMIzZk_abc
   ```
6. Guardar ese token.

### Paso 2 — Obtener el Chat ID

1. Buscar el bot en Telegram y escribirle cualquier mensaje
2. Abrir esta URL en el navegador (reemplazar TOKEN por el token obtenido):
   ```
   https://api.telegram.org/botTOKEN/getUpdates
   ```
3. En el JSON que aparece, buscar el número en el campo `"id"` dentro de `"chat"`. Ese es el **Chat ID**.

### Paso 3 — Configurar el nodo Telegram en n8n

1. Abrir el workflow en n8n
2. Hacer clic en el nodo **Send a text message**
3. En **Credential** crear nueva credencial con el token propio
4. En **Chat ID** ingresar el Chat ID propio
5. Publicar el workflow con el botón **Publish**

### Tipos de alertas que envía el sistema

El sistema envía alertas automáticas solo para eventos críticos:

**Login exitoso:**
```
🚨 ALERTA DE INTRUSIÓN 🚨

Tipo: LOGIN EXITOSO
IP Atacante: 172.18.0.1
Usuario: root
Contraseña: admin123
Sesión: 8126d0746549
Fecha: 16/4/2026
Hora: 13:01:31

🤖 Detectado automáticamente por Honeypot OSCORP
```

**Descarga de archivo malicioso:**
```
🚨 ALERTA DE INTRUSIÓN 🚨

Tipo: DESCARGA DE ARCHIVO
IP Atacante: 172.18.0.1
Hash del archivo: fb91d75a6bb430787a61b0aec5...
Sesión: 8126d0746549
Fecha: 16/4/2026
Hora: 13:01:53

🤖 Detectado automáticamente por Honeypot OSCORP
```

---

## ⚙️ Pipeline Automatizado

A diferencia de versiones anteriores, el pipeline **no requiere ejecución manual**. El Schedule Trigger se activa automáticamente cada 1 minuto.

### Flujo completo del pipeline

```
Schedule Trigger (cada 1 min)
    ↓
Read cowrie.json
    ↓
Code — parsear NDJSON y filtrar solo eventos nuevos
    ↓
Filter — dejar pasar solo eventos con eventid cowrie.*
    ↓
    ├── Insert rows → PostgreSQL
    ├── Create document → Elasticsearch
    └── Filtro Atacantes → Telegram (solo login.success y file_download)
```

### Para activar el sistema

1. Importar el workflow en n8n
2. Configurar las tres credenciales (PostgreSQL, Elasticsearch, Telegram)
3. Hacer clic en **Publish** arriba a la derecha
4. El sistema queda activo y procesa ataques automáticamente

### Para verificar que funciona

Simular un ataque:

```bash
ssh root@localhost -p 2222
```

Esperar 1 minuto. Debe llegar una alerta automática a Telegram.

---

## 📊 Dashboards en Kibana

### Configurar Data View

1. Ir a http://localhost:5601
2. Ir a **Stack Management → Data Views**
3. Crear un Data View con estos parámetros:

| Campo           | Valor               |
|-----------------|---------------------|
| Name            | eventos_honeypot    |
| Index pattern   | eventos_honeypot*   |
| Timestamp field | timestamp           |

### Dashboards disponibles

| Panel                          | Tipo  | Descripción                              |
|--------------------------------|-------|------------------------------------------|
| Distribución de Comandos       | Dona  | Comandos ejecutados por atacantes        |
| Top IPs de Origen              | Tabla | IPs que más atacaron                     |
| Actividad Temporal de Ataques  | Barras| Ataques por día/hora                     |
| Indicadores de Compromiso      | Tabla | Hashes SHA-256 de archivos maliciosos    |

---

## 🗄️ Estructura del Repositorio

```
Proyecto-honeypots/
├── docker/
│   └── docker-compose.yml          → Configuración de todos los contenedores
├── database/
│   └── schema.sql                  → Script SQL para crear la tabla eventos
├── scripts/
│   ├── analizar_cowrie.py          → Script Python para analizar logs
│   └── workflow_honeypot.json      → Workflow exportado de n8n (importar en n8n)
├── logs/
│   └── cowrie.json                 → Logs generados por Cowrie
├── docs/
│   └── informe.pdf                 → Documento de tesis
└── README.md                       → Este archivo
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

### Ver uso de recursos

```bash
docker stats --no-stream
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

> **Nota:** Si aparece error de zona horaria, agregar `-Duser.timezone=UTC` al archivo `dbeaver.ini`.

### Desde terminal

```bash
docker exec -it db-honeypot psql -U admin -d honeypot
```

### Consultas útiles

```sql
-- Ver todos los eventos ordenados por fecha
SELECT * FROM eventos ORDER BY timestamp DESC;

-- Ver solo logins exitosos
SELECT timestamp, src_ip, username, password
FROM eventos
WHERE username IS NOT NULL
ORDER BY timestamp DESC;

-- Ver comandos ejecutados
SELECT timestamp, src_ip, command
FROM eventos
WHERE command IS NOT NULL
ORDER BY timestamp DESC;

-- Contar eventos por IP atacante
SELECT src_ip, COUNT(*) as total
FROM eventos
GROUP BY src_ip
ORDER BY total DESC;

-- Ver indicadores de compromiso (hashes)
SELECT hash, COUNT(*) as veces_descargado
FROM eventos
WHERE hash IS NOT NULL
GROUP BY hash
ORDER BY veces_descargado DESC;
```

---

## 🐍 Script de Análisis Python

```bash
cd scripts
python analizar_cowrie.py
```

Muestra en consola los eventos clasificados por tipo.

---

## ⚠️ Consideraciones de Seguridad

- Este sistema está diseñado exclusivamente para uso en **entornos controlados de laboratorio**.
- El honeypot simula un servidor vulnerable. No exponer a internet sin supervisión.
- Las credenciales de la base de datos son de desarrollo. No usar en producción.
- Elasticsearch tiene la seguridad desactivada (`xpack.security.enabled=false`) para facilitar el laboratorio.
- Cada operador debe usar su propio bot de Telegram. No compartir tokens de acceso.

---

## 📚 Referencias

- Cowrie Honeypot: https://github.com/cowrie/cowrie
- n8n Documentation: https://docs.n8n.io
- Elasticsearch Guide: https://www.elastic.co/guide
- PostgreSQL Documentation: https://www.postgresql.org/docs
- Telegram Bot API: https://core.telegram.org/bots/api

---

## 📄 Licencia

Proyecto académico — Tecnicatura en Programación — 2026  
Grupo Oscorp — López, Santiago & Morato, Elizabeth
