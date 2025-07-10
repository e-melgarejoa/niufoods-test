# NIU Foods - Sistema de Monitoreo de Dispositivos

Este proyecto simula un sistema de monitoreo de dispositivos distribuidos en diferentes locales, centralizando la información en una API. Permite observar el estado de cada dispositivo y local, facilitando la gestión y el diagnóstico de problemas en tiempo real.

## Arquitectura del Proyecto

- **Backend (API central):** Aplicación Rails que expone endpoints para recibir y consultar el estado de los dispositivos.
- **Simulador de Dispositivos:** Script que emula la actividad y los estados de los dispositivos, enviando datos periódicamente a la API.

---

## Modelo de Base de Datos

```mermaid
erDiagram
    DeviceType ||--o{ Device : "has"
    Device ||--o{ DeviceApiRequest : "has"
    Device ||--o| DeviceUpdate : "has"
    Local ||--o{ LocalDevice : "has"
    Device ||--o{ LocalDevice : "has"
    DeviceApiRequest ||--o| DeviceUpdate : "referenced by successful"
    DeviceApiRequest ||--o| DeviceUpdate : "referenced by failed"

    DeviceType {
        bigint id PK
        string name "UK, not null"
        text description
        boolean active "default: true, not null"
        datetime created_at
        datetime updated_at
    }

    Device {
        bigint id PK
        bigint device_type_id FK "not null"
        string uuid "UK, not null"
        string name
        string manufacturer
        string model
        string serial_number "UK, not null, unique where not null"
        datetime last_connection_at
        boolean active
        datetime created_at
        datetime updated_at
    }

    DeviceApiRequest {
        bigint id PK
        bigint device_id FK "not null"
        string sidekiq_job_id "UK, not null, unique where not null"
        integer status "default: 0, not null (pending, processing, completed, failed)"
        jsonb request_payload
        string api_endpoint
        datetime processed_at
        datetime completed_at
        text error_message
        text stack_trace
        integer retries_count "default: 0, not null"
        datetime created_at
        datetime updated_at
    }

    DeviceUpdate {
        bigint id PK
        bigint device_id FK "not null"
        integer last_update_status "default: 1, not null (pending, in_progress, success, failed)"
        integer operational_status "default: 0, not null (unknown, operative, warning, trouble, failing, in_maintenance)"
        datetime last_updated_at
        datetime last_sync_time
        string current_firmware_version
        string desired_firmware_version
        bigint last_successful_request_id FK
        bigint last_failed_request_id FK
        text last_error_message
        datetime created_at
        datetime updated_at
    }

    Local {
        bigint id PK
        string name "UK, not null"
        string address
        string city
        string region
        datetime created_at
        datetime updated_at
        integer operational_status "default: 0 (unknown, operative, warning, trouble, failing, in_maintenance)"
    }

    LocalDevice {
        bigint id PK
        bigint local_id FK "not null"
        bigint device_id FK "not null"
        datetime assigned_from
        datetime assigned_until
        boolean is_current "unique on (device_id, is_current) where is_current is true"
        datetime created_at
        datetime updated_at
    }
```
---

## Lógica de Actualización de Estados y Mantenimiento

La lógica del negocio implementada en los modelos de la aplicación Rails asegura que las actualizaciones de estado de los dispositivos y la gestión de los registros de mantenimiento se reflejen correctamente en el sistema:

- **Actualización de Estado de Dispositivos:**  
    Cada vez que un dispositivo reporta un nuevo estado, el modelo correspondiente actualiza su registro en la base de datos. Si el dispositivo entra en mantenimiento (`in_maintenance`), se crea un registro de mantenimiento asociado, indicando el inicio del proceso.

- **Gestión de Registros de Mantenimiento:**  
    Los registros de mantenimiento permiten llevar un historial de cuándo un dispositivo entra y sale de mantenimiento. Cuando un dispositivo sale de mantenimiento y vuelve a un estado operativo, el registro se actualiza para reflejar la finalización del mantenimiento.

- **Impacto en el Estado del Restaurante:**  
    La lógica de precedencia en el modelo del restaurante evalúa el estado global considerando tanto los estados normales (`operative`, `failing`, `trouble`, `unknown`) como los de mantenimiento. Si algún dispositivo está en `failing`, el restaurante se marca como `failing`. Si no hay dispositivos en `failing` pero sí en `trouble`, el restaurante se marca como `trouble`. Los dispositivos en `in_maintenance` no afectan negativamente el estado global, permitiendo que el restaurante se considere `operative` si los demás dispositivos están en buen estado o en mantenimiento.

- **Consistencia y Automatización:**  
    Toda esta lógica se encuentra encapsulada en los modelos, utilizando callbacks y métodos personalizados para asegurar que cualquier cambio de estado o registro de mantenimiento actualice automáticamente el estado global del restaurante y el historial de mantenimiento de los dispositivos.

---

## Diagrama General de Conexión

```mermaid
flowchart TD
        D1["Dispositivo 1"]
        D2["Dispositivo 2"]
        Dn["Dispositivo N"]
        API["API Central (Rails)"]
        Cliente["Cliente Web / CLI"]

        D1 -- "POST estado" --> API
        D2 -- "POST estado" --> API
        Dn -- "POST estado" --> API
        API -- "Consulta estados" --> Cliente
```

- Cada dispositivo simulado genera eventos de estado y los envía mediante peticiones HTTP a la API central.
- La API central almacena y procesa los estados recibidos.

---

```mermaid
flowchart TD
        A[Dispositivo simulado genera estado] --> B[Envía POST a API central]
        B --> C{¿POST recibido correctamente?}
        C -- Sí --> D[API encola job en Sidekiq]
        D --> E[Sidekiq procesa y guarda estado]
        E --> F[Actualiza estado del local según precedencia]
        F --> G[Disponible para consulta por cliente]
        C -- No --> H[API responde con error]
        H --> I[Dispositivo puede reintentar envío o registrar error]
```

- Los dispositivos simulan cambios de estado y envían los datos a la API.
- La API valida la estructura y contenido del mensaje.
- Si es válido, almacena el estado y actualiza el estado global del local según la lógica de precedencia.
- Si ocurre un error (por ejemplo, datos inválidos), la API responde con un mensaje de error y el dispositivo puede reintentar o registrar el fallo.

---

## Pasos para Ejecutar el Proyecto

1. **Requisitos previos**
     - Tener Docker instalado (versión >= 28).

2. **Clonar el repositorio**
     ```sh
     git clone <URL_DEL_REPOSITORIO>
     cd niufoods-test
     ```

3. **Iniciar los servicios**
     ```sh
     docker-compose up
     ```
     Esto levantará la API central y los servicios necesarios.

4. **Ejecutar la simulación de dispositivos**
     ```sh
     docker-compose run --rm backend bundle exec rails runner simulate_device_activity.rb
     ```
     Esto iniciará el script que simula la actividad de los dispositivos y enviará los datos a la API.

---

## Comandos Útiles

| Comando                                      | Alias                    | Descripción                                                                                      |
|----------------------------------------------|--------------------------|--------------------------------------------------------------------------------------------------|
| `docker-compose up`                          | `dcup`                   | Inicia el entorno de desarrollo (todos los servicios)                                            |
| `docker-compose stop`                        | `dcstop`                 | Detiene el entorno de desarrollo (todos los servicios)                                           |
| `docker-compose up backend`                  | `dcup backend`           | Inicia solo el backend (API)                                                                     |
| `docker-compose ps`                          | `dcps`                   | Muestra el estado de los contenedores en ejecución                                               |
| `docker-compose exec backend bash`           | `dce backend bash`       | Abre una terminal dentro del contenedor                                                          |
| `docker-compose exec backend rails c`        | `dce backend rails c`    | Abre la consola de Rails dentro del contenedor                                                   |
| `docker-compose exec backend {comando}`      | `dce backend {comando}`  | Ejecuta cualquier comando dentro de un contenedor en particular                                  |
| `docker-compose run backend {comando}`       | `dcr backend {comando}`  | Ejecuta cualquier comando dentro de un contenedor y lo inicia automáticamente                    |

### Nota sobre el levantamiento del proyecto

Para asegurar que los contenedores se construyan con la última versión de la imagen y se ejecuten en segundo plano, se recomienda iniciar los servicios con:

```sh
docker-compose up -d --build
```

- El flag `--build` fuerza la reconstrucción de las imágenes, útil si hubo cambios en el código o dependencias.
- El flag `-d` ejecuta los servicios en modo "detached" (en segundo plano).

Puedes omitir `--build` si no hubo cambios recientes, y `-d` si prefieres ver los logs en la terminal.

## Consideraciones

- **Variables y configuración:** Los archivos de configuración y variables incluidos son solo para facilitar la revisión. **No** los uses en proyectos reales o entornos productivos.
- **Persistencia:** Los datos se almacenan en la base de datos definida en el entorno Docker.
- **Errores:** Si la API recibe datos inválidos, responde con un error y no almacena la información.
- **Portabilidad:** Todo el entorno está preparado para ejecutarse en cualquier máquina con Docker.

---

¿Dudas o sugerencias? ¡Contribuciones y mejoras son bienvenidas!

