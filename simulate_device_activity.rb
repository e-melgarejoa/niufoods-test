
require 'faker'
require 'json'
require 'time'

# Cargar el entorno de Rails si no estamos ya en un runner
unless defined?(Rails)
  puts "Loading Rails environment..."
  require File.expand_path('../config/environment', __dir__)
  puts "Rails environment loaded."
end

# --- INICIO DEL BLOQUE 'begin' QUE ENVUELVE EL CÓDIGO PRINCIPAL ---
begin # <--- ¡Añadir este 'begin' aquí!

  puts "--- Starting Device Activity Simulation ---"

  # Intervalo de tiempo máximo entre interacciones de un dispositivo (en segundos)
  MAX_INTERACTION_INTERVAL = 300 # 5 minutos

  # Probabilidad de que una interacción termine en un error simulado (0.0 a 1.0)
  ERROR_PROBABILITY = 0.20 # 20% de probabilidad de error

  # Probabilidad de simular diferentes estados operativos (debe sumar 1.0 para cada dispositivo)
  OPERATIONAL_STATUS_PROBABILITIES = {
    operative: 0.70,
    warning: 0.15,
    trouble: 0.10,
    failing: 0.03,
    in_maintenance: 0.02
  }.freeze

  # Genera un estado operativo aleatorio basado en las probabilidades
  def generate_random_operational_status
    rand_num = rand
    cumulative_probability = 0.0
    OPERATIONAL_STATUS_PROBABILITIES.each do |status, probability|
      cumulative_probability += probability
      return status.to_s if rand_num <= cumulative_probability
    end
    'unknown'
  end

  # Simula un payload de datos de un dispositivo
  def generate_device_payload(device)
    payload = {
      "firmware_version": device.firmware_version,
      "battery_level": rand(10..100),
      "temperature": Faker::Number.between(from: 18.0, to: 35.0).round(1),
      "uptime_hours": Faker::Number.between(from: 24, to: 720),
      "operational_status": generate_random_operational_status,
      "sync_time": Time.current.iso8601
    }

    case device.device_type.name
    when 'Kiosk'
      payload["screen_brightness"] = rand(50..100)
      payload["disk_usage_percent"] = rand(10..90)
    when 'Sensor'
      payload["humidity"] = Faker::Number.between(from: 30.0, to: 90.0).round(1)
      payload["ambient_light"] = rand(100..1000)
    when 'POS Terminal'
      payload["transactions_today"] = rand(50..500)
      payload["last_transaction_value"] = Faker::Commerce.price(range: 10.0..500.0).round(2)
    when 'Digital Signage'
      payload["current_content_id"] = Faker::Alphanumeric.alphanumeric(number: 10).upcase
      payload["playlist_version"] = Faker::App.version
    when 'Printer'
      payload["paper_level_percent"] = rand(0..100)
      payload["toner_level_percent"] = rand(0..100)
      payload["pages_printed_since_last_service"] = rand(1000..10000)
    end

    payload
  end

  def send_device_data(device, local, is_error_case = false)
    payload = generate_device_payload(device)
    api_endpoint = '/api/v1/devices/update_status'

    if is_error_case
      case rand(1..3)
      when 1
        # Simular un payload malformado
        payload.delete("operational_status") # Campo requerido faltante
        payload["firmware_version"] = nil # Dato inválido
        error_message = "Simulated: Invalid payload structure or missing critical data."
      when 2
        # Simular un error de autenticación/UUID desconocido
        api_endpoint = '/api/v1/devices/non_existent_endpoint' # Endpoint incorrecto
        error_message = "Simulated: Unauthorized access or incorrect endpoint."
      when 3
        # Simular un error de servidor interno
        payload["simulate_server_error"] = true # Un campo que tu worker podría interpretar como un error
        error_message = "Simulated: Internal server error on processing."
      end
      Rails.logger.warn "Simulating ERROR case for Device #{device.uuid}: #{error_message}"
    end

    begin
      # Crea el DeviceApiRequest que será procesado por el Sidekiq Worker
      api_request = device.device_api_requests.create!(
        request_payload: payload,
        api_endpoint: api_endpoint,
        status: :pending, # Se inicializa como 'pending'
        sidekiq_job_id: SecureRandom.hex(12) # Simula un ID de Sidekiq
      )
      puts "  [#{Time.current.strftime('%H:%M:%S')}] Device #{device.uuid} (#{device.device_type.name}) at #{local.name} sent data. API Request ID: #{api_request.id} (Error: #{is_error_case})"

      # Encola el trabajo de Sidekiq para procesar esta solicitud API
      DeviceUpdateJob.perform_async(api_request.id)

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to create DeviceApiRequest for device #{device.uuid}: #{e.message}"
    end
  end

  all_devices_with_locals = Device.includes(:device_type, local_devices: :local)
                                  .map do |device|
                                    current_local_device = device.local_devices.find_by(is_current: true)
                                    [device, current_local_device&.local] if current_local_device
                                  end.compact

  if all_devices_with_locals.empty?
    puts "No active devices found in locals to simulate activity. Please run `rails db:seed` first."
    exit 0
  end

  puts "\nStarting simulation for #{all_devices_with_locals.count} devices..."
  puts "Press Ctrl+C to stop the simulation."

  # Bucle infinito para simular actividad continua
  loop do
    all_devices_with_locals.each do |device, local|
      # Simular un intervalo irregular para cada dispositivo
      sleep_time = rand(1..MAX_INTERACTION_INTERVAL)
      puts "  Next update for #{device.uuid} in #{sleep_time} seconds..."
      sleep sleep_time

      # Decidir si esta interacción será un caso de error o éxito
      is_error = rand < ERROR_PROBABILITY

      send_device_data(device, local, is_error)
    end
  end

rescue Interrupt
  puts "\n--- Device Activity Simulation Stopped ---"
rescue StandardError => e
  Rails.logger.error "Simulation script error: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
  puts "Simulation script encountered an error. Check logs."
end # <--- ¡Cierra el 'begin' aquí!