# MarAzul Sucre

Proyecto académico de base de datos para gestionar organizaciones pesqueras, pescadores, embarcaciones, jornadas, capturas y ventas.

**Autor:** Juan Diego Quiroz Perez  
**Asignatura:** Base de Datos  
**Institución:** Corporación Universitaria del Caribe — CECAR

## Herramientas

- MySQL 8.0 y MySQL Workbench.
- Docker Desktop.
- MongoDB Community Server 8.0 y mongosh.
- PostgreSQL 17 y psql.

## Archivos

| Archivo | Contenido |
|---|---|
| `scripts_sql/01_DDL.sql` | Creación del esquema base de MySQL, tablas y restricciones. |
| `scripts_sql/01_DDL_COMPLEMENTARIO.sql` | Ejercicios de creación de inspecciones de calidad y modificación de estructuras e índices. |
| `scripts_sql/01_REGISTROS.sql` | Carga inicial de datos sintéticos. |
| `scripts_sql/02_DML_JOIN.sql` | Consultas con JOIN. |
| `scripts_sql/03_DML_SUBCONSULTAS.sql` | Subconsultas correlacionadas y no correlacionadas. |
| `scripts_sql/04_DCL.sql` | Usuarios, roles, permisos y pruebas de acceso. |
| `scripts_sql/05_TCL.sql` | Ejercicios de COMMIT, ROLLBACK y SAVEPOINT. |
| `scripts_sql/06_VISTAS.sql` | Tres vistas de negocio. |
| `scripts_sql/07_FUNCIONES.sql` | Tres funciones almacenadas y consultas de comprobación. |
| `scripts_sql/08_PROCEDIMIENTOS.sql` | Preparación del saldo disponible y tres procedimientos almacenados. |
| `scripts_sql/09_TRIGGERS.sql` | Tres triggers de disponibilidad y auditoría. |
| `nosql/10_NOSQL.js` | Carga de cinco diarios de campo y consultas en MongoDB. |
| `migracion/12_MIGRACION.sql` | Creación de las tablas y carga del respaldo adaptado a PostgreSQL. |
| `migracion/12_MIGRACION_FUNCION.sql` | Función de eficiencia adaptada a PostgreSQL. |
| `documentacion/Diagrama MarAzul.png` | Diagrama físico del modelo. |
| `documentacion/Diagrama MarAzul.mwb` | Modelo editable en MySQL Workbench. |
| `vectorial/Propuesta Vectorial MarAzul.pdf` | Propuesta de búsqueda semántica y cinco textos seleccionados. |
| `documentacion/PARCIAL - BASE DE DATOS.pdf` | Informe técnico con explicaciones y evidencias. |

La propuesta vectorial se incluye tanto en el informe como en el archivo independiente `vectorial/Propuesta Vectorial MarAzul.pdf`. Se trata de una propuesta explicativa; no se implementó una búsqueda vectorial ejecutable.

## Ubicación y terminal de trabajo

La carpeta utilizada en el equipo de desarrollo es:

```text
D:\PROYECTO DE BASE DE DATOS
```

Para ejecutar los comandos de Docker de este documento, abrir PowerShell y ubicarse en esa carpeta:

```powershell
Set-Location -LiteralPath 'D:\PROYECTO DE BASE DE DATOS'
```

En otro equipo debe utilizarse la ubicación donde se descargue el proyecto. Los comandos con rutas relativas parten de esa carpeta.

## MySQL

La base utilizada es `marazul_sucre`. Los archivos SQL se abren en MySQL Workbench. No deben ejecutarse todos sobre una base existente: contienen operaciones de creación y ejercicios que modifican datos.

### Estado de los archivos de creación

Los scripts conservan diferencias pendientes que impiden considerarlos una instalación automática desde cero:

- `scripts_sql/01_DDL.sql` define algunos valores de dominio en inglés, mientras que `scripts_sql/01_REGISTROS.sql` utiliza valores en español.
- `scripts_sql/01_DDL_COMPLEMENTARIO.sql` contiene `EXELENTE` en lugar de `EXCELENTE` y un valor predeterminado `INSHORE` que no coincide con el dominio del ejercicio.
- La columna de autonomía y el índice comercial aparecen tanto en el esquema base como en el DDL complementario.

Estas diferencias deben resolverse antes de reconstruir la base desde cero. Renombrar los archivos no modifica su contenido. Las capturas del informe corresponden a la base utilizada durante las prácticas, que recibió ajustes durante el desarrollo.

### Secuencia prevista

Una vez resueltas las diferencias anteriores, la secuencia es:

1. `scripts_sql/01_DDL.sql`.
2. `scripts_sql/01_DDL_COMPLEMENTARIO.sql`, evitando duplicar columnas e índices.
3. `scripts_sql/01_REGISTROS.sql`.
4. `scripts_sql/02_DML_JOIN.sql` y `scripts_sql/03_DML_SUBCONSULTAS.sql`.
5. `scripts_sql/04_DCL.sql`, separando la configuración administrativa de las pruebas en las sesiones de cada usuario.
6. `scripts_sql/05_TCL.sql`, por bloques y siguiendo sus comentarios.
7. `scripts_sql/06_VISTAS.sql` y `scripts_sql/07_FUNCIONES.sql`.
8. `scripts_sql/08_PROCEDIMIENTOS.sql`.
9. `scripts_sql/09_TRIGGERS.sql`.

El ejercicio SAVEPOINT del TCL provoca un error intencional por peso negativo. Después del error esperado se continúa con `ROLLBACK TO SAVEPOINT` y `COMMIT` según indica el archivo.

La preparación de `scripts_sql/08_PROCEDIMIENTOS.sql` agrega `available_weight_kg` e inicializa el saldo de las capturas existentes. Se ejecuta una sola vez. Los triggers se crean después de que exista esa columna.

### Usuarios de prueba

| Usuario | Contraseña de prueba | Perfil |
|---|---|---|
| `usr_inspector1` | `Inspector_Juan_2026!` | Consulta de jornadas, capturas y especies. |
| `usr_operador1` | `Operador_Juan_2026!` | Registro y actualización de jornadas y capturas. |
| `usr_comercial1` | `Comercial_Juan_2026!` | Registro y actualización de ventas y detalles. |

Las cuentas están definidas para `localhost`. Son credenciales del entorno académico de prueba.

## MongoDB en Docker

- Contenedor: `marazul-mongodb`.
- Base: `marazul_field_logs`.
- Colección: `field_diaries`.
- Puerto local: `127.0.0.1:27017`.
- Volumen: `marazul_mongo_data`.

### Crear el servicio en un equipo nuevo

Con Docker Desktop iniciado, ejecutar una sola vez:

```powershell
docker run -d --name marazul-mongodb -p 127.0.0.1:27017:27017 -v marazul_mongo_data:/data/db mongodb/mongodb-community-server:8.0-ubuntu2204
```

Si el contenedor ya existe y está detenido, utilizar en su lugar:

```powershell
docker start marazul-mongodb
```

Comprobar la conexión:

```powershell
docker exec marazul-mongodb mongosh --quiet --eval "db.runCommand({ping: 1})"
```

Resultado esperado: `{ ok: 1 }`.

### Cargar y consultar los diarios

Ejecutar únicamente en una colección nueva o vacía:

```powershell
docker cp ".\nosql\10_NOSQL.js" marazul-mongodb:/tmp/10_NOSQL.js
docker exec marazul-mongodb mongosh --quiet --file /tmp/10_NOSQL.js
```

No repetir la carga sobre la colección actual: los identificadores del 1 al 5 ya existen. El archivo se ejecuta con `mongosh`, no en MySQL Workbench.

Resultados esperados de las consultas:

- Consulta general: cinco diarios.
- Fallas mecánicas: jornadas 3 y 5.
- Pérdida de redes: jornadas 4 y 5.
- Fallas mecánicas o pérdida de redes: jornadas 3, 4 y 5.

El entorno local de MongoDB no tiene autenticación habilitada.

## PostgreSQL en Docker

- Contenedor: `marazul-postgres`.
- Base: `marazul_sucre`.
- Usuario: `marazul_admin`.
- Contraseña de prueba: `MarAzul_2026!`.
- Puerto del equipo: `127.0.0.1:5433`.
- Puerto del contenedor: `5432`.
- Volumen: `marazul_postgres_data`.

### Crear el servicio en un equipo nuevo

Ejecutar una sola vez:

```powershell
docker run -d --name marazul-postgres -e POSTGRES_USER=marazul_admin -e POSTGRES_PASSWORD=MarAzul_2026! -e POSTGRES_DB=marazul_sucre -p 127.0.0.1:5433:5432 -v marazul_postgres_data:/var/lib/postgresql/data postgres:17
```

Si el contenedor ya existe y está detenido, utilizar en su lugar:

```powershell
docker start marazul-postgres
```

Comprobar el servicio:

```powershell
docker exec marazul-postgres pg_isready -U marazul_admin -d marazul_sucre
```

Antes de importar, la respuesta debe indicar `accepting connections`.

### Importar las tablas y los datos

Ejecutar una sola vez en la base de destino vacía:

```powershell
docker cp ".\migracion\12_MIGRACION.sql" marazul-postgres:/tmp/12_MIGRACION.sql
docker exec marazul-postgres psql -X -U marazul_admin -d marazul_sucre -v ON_ERROR_STOP=1 -f /tmp/12_MIGRACION.sql
```

El archivo importa 24 tablas con 686 registros e incorpora las restricciones e índices adaptados. La salida final esperada es `Carga de tablas y datos completada`.

### Crear y comprobar la función migrada

Ejecutar la creación una sola vez:

```powershell
docker cp ".\migracion\12_MIGRACION_FUNCION.sql" marazul-postgres:/tmp/12_MIGRACION_FUNCION.sql
docker exec marazul-postgres psql -X -U marazul_admin -d marazul_sucre -v ON_ERROR_STOP=1 -f /tmp/12_MIGRACION_FUNCION.sql
```

Consultar el resultado:

```powershell
docker exec marazul-postgres psql -U marazul_admin -d marazul_sucre -c "SELECT fn_trip_efficiency(1) AS eficiencia_porcentaje;"
```

Resultado esperado: `27.40`.

### Validaciones de la migración

Conteos:

```powershell
docker exec marazul-postgres psql -U marazul_admin -d marazul_sucre -c "SELECT 'trips' AS table_name, COUNT(*) AS row_count FROM trips UNION ALL SELECT 'catches', COUNT(*) FROM catches UNION ALL SELECT 'sales', COUNT(*) FROM sales UNION ALL SELECT 'sale_details', COUNT(*) FROM sale_details;"
```

| Tabla | Registros |
|---|---:|
| `trips` | 40 |
| `catches` | 200 |
| `sales` | 44 |
| `sale_details` | 167 |

Integridad referencial:

```powershell
docker exec marazul-postgres psql -U marazul_admin -d marazul_sucre -c "SELECT COUNT(*) AS total_claves_foraneas, COUNT(*) FILTER (WHERE convalidated) AS claves_validadas FROM pg_constraint WHERE contype = 'f' AND connamespace = 'public'::regnamespace;"
```

Resultado esperado: 29 claves foráneas y 29 validadas.

Totales comerciales:

```powershell
docker exec marazul-postgres psql -U marazul_admin -d marazul_sucre -c "SELECT SUM(sold_weight_kg) AS total_vendido_kg, SUM(sold_weight_kg * unit_price) AS valor_total_ventas FROM sale_details;"
```

Resultados esperados: `2728.600` kg vendidos y `53102400.00000` COP de valor total.

Los datos migrados corresponden a un estado posterior a las prácticas TCL. Por eso la carga inicial de MySQL incluye 40 ventas y 160 detalles, mientras el archivo de migración incluye 44 ventas y 167 detalles.

## Alcance de la entrega

- El despliegue se realizó localmente; no se dispone de un enlace público de acceso a los servicios.
- MongoDB y MySQL se relacionan conceptualmente mediante `id_trip`, sin sincronización automática.
- PostgreSQL conserva una copia del estado utilizado durante la migración; no replica los cambios posteriores de MySQL.
- Se migraron las tablas, los datos y una función, no todos los objetos programables.
- La búsqueda vectorial se documentó como propuesta con cinco textos; no se implementó un índice ni una consulta real de similitud.
- El informe contiene las explicaciones y las evidencias de las prácticas realizadas.
