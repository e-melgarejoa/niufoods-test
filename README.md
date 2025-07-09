# Consideraciones
Proyecto realizado en Docker para facilitar la ejecución y portabilidad.

- **Requisito:** Docker instalado (versión >= 28).
- **Nota:** Los archivos de configuración y variables se incluyen solo para facilitar la revisión. **No** los uses en proyectos reales o entornos productivos.

---

## Comandos útiles para la ejecución del proyecto

| Comando                                      | Alias                    | Descripción                                                                                      |
|----------------------------------------------|--------------------------|--------------------------------------------------------------------------------------------------|
| `docker-compose up`                          | `dcup`                   | Inicia el entorno de desarrollo (todos los servicios)                                            |
| `docker-compose stop`                        | `dcstop`                 | Detiene el entorno de desarrollo (todos los servicios)                                           |
| `docker-compose up backend`                  | `dcup backend`           | Inicia solo el backend (API)                                                                     |
| `docker-compose up backend client`           | `dcup backend client`    | Inicia tanto el backend como el cliente                                                          |
| `docker-compose ps`                          | `dcps`                   | Muestra el estado de los contenedores en ejecución                                               |
| `docker-compose exec backend bash`           | `dce backend bash`       | Abre una terminal dentro del contenedor                                                          |
| `docker-compose exec backend rails c`        | `dce backend rails c`    | Abre la consola de Rails dentro del contenedor                                                   |
| `docker-compose exec backend {comando}`      | `dce backend {comando}`  | Ejecuta cualquier comando dentro de un contenedor en particular                                  |
| `docker-compose run backend {comando}`       | `dcr backend {comando}`  | Ejecuta cualquier comando dentro de un contenedor y lo inicia automáticamente                    |

## Ejecución y observación de simulación
Para ejecutar la simulación, utiliza el siguiente comando en tu terminal:

```sh
docker-compose run --rm backend bundle exec rails runner simulate_device_activity.rb
```
