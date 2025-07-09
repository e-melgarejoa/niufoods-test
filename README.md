# Consideraciones
Proyecto realizado en Docker para facilitar ejecución y portabilidad

- Se requiere que Docker esté instalado en su version >= 28
- Se deja para facilitar la revisión archivos de configuración y variables (no considerar esto para proyectos reales o en entornos productivos).

# Comandos útiles para ejecución del proyecto

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
