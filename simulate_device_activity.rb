require 'faker'
require 'json'
require 'time'
require 'httparty' # Permite hacer peticiones HTTP POST a la API

# Carga el entorno de Rails si el script no se ejecuta con `rails runner`
unless defined?(Rails)
  require File.expand_path('../config/environment', __dir__)
end

begin
  puts "--- Iniciando Simulación de Actividad de Dispositivos ---"

  # URL base de tu API de Rails (ajusta si es necesario)
  BASE_API_URL = "http://localhost:3000"

  # Intervalo de tiempo máximo entre interacciones por dispositivo (en segundos)
  MAX_INTERACTION_INTERVAL = 300 # 5 minutos

  # Probabilidad de que una interacción simule un error (0.0 a 1.0)
  ERROR_PROBABILITY = 0.20 # 20% de probabilidad de error

  # Probabilidades para los estados operativos simulados
  OPERATIONAL_STATUS_PROBABILITIES = {
    operative: 0.70,
    warning: 0.15,
    trouble: 0.10,
    failing: 0.03,
    in_maintenance: 0.02
  }.freeze

  # Genera un estado operacional aleatorio basado en las probabilidades definidas
  def generate_random_operational_status
    rand_num = rand
    cumulative_probability = 0.0
    OPERATIONAL_STATUS_PROBABILITIES.each do |status, probability|
      cumulative_probability += probability
      return status.to_s if rand_num <= cumulative_probability
    end
    'unknown'
  end

  # Genera un payload de datos de dispositivo simulado
  def generate_device_payload(device)
    payload = {
      "firmware_version": device.firmware_version,
      "battery_level": rand(10..100),
      "temperature": Faker::Number.between(from: 18.0, to: 35.0).round(1),
      "uptime_hours": Faker::Number.between(from: 24, to: 720),
      "operational_status": generate_random_operational_status,
      "sync_time": Time.current.iso8601
    }

    # Añade datos específicos según el tipo de dispositivo
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

  # Envía datos del dispositivo a la API de Rails
  def send_device_data(device, local, is_error_case = false)
    api_payload = {
      device_uuid: device.uuid,
      data: generate_device_payload(device)
    }
    
    request_url = "#{BASE_API_URL}/api/v1/devices/update_status"
    error_type_simulated = nil

    if is_error_case
      case rand(1..3)
      when 1
        api_payload.delete(:data) # Simula payload malformado
        api_payload[:invalid_data_key] = generate_device_payload(device)
        error_type_simulated = "Payload malformado (clave 'data' faltante)"
      when 2
        api_payload[:device_uuid] = Faker::Internet.uuid # Simula UUID inexistente
        error_type_simulated = "UUID inexistente"
      when 3
        api_payload[:data]["force_server_error"] = true # Simula error interno en el worker
        error_type_simulated = "Error interno de servidor simulado"
      end
      Rails.logger.warn "Simulando CASO DE ERROR para Dispositivo #{device.uuid}: #{error_type_simulated}"
    end

    begin
      # Realiza la petición HTTP POST real a la API
      response = HTTParty.post(
        request_url,
        body: api_payload.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      response_body = JSON.parse(response.body) rescue { message: response.body }
      
      if response.success?
        puts "  [#{Time.current.strftime('%H:%M:%S')}] ✅ Dispositivo #{device.uuid} (#{device.device_type.name}) en #{local.name} envió datos. Estado HTTP: #{response.code}. Respuesta API: #{response_body['message']}. ID de Solicitud: #{response_body['request_id']}"
      else
        puts "  [#{Time.current.strftime('%H:%M:%S')}] ❌ Dispositivo #{device.uuid} (#{device.device_type.name}) en #{local.name} FALLÓ al enviar datos. Estado HTTP: #{response.code}. Error API: #{response_body['error']}. Tipo de Error Simulado: #{error_type_simulated}"
      end

    rescue HTTParty::Error => e
      Rails.logger.error "Error HTTParty al enviar datos para dispositivo #{device.uuid}: #{e.message}"
      puts "  [#{Time.current.strftime('%H:%M:%S')}] ❌ Dispositivo #{device.uuid} (#{device.device_type.name}) en #{local.name} FALLÓ debido a error de red/HTTP: #{e.message}"
    rescue JSON::ParserError
      Rails.logger.error "Error de parseo JSON para dispositivo #{device.uuid}. Cuerpo de respuesta: #{response.body}"
      puts "  [#{Time.current.strftime('%H:%M:%S')}] ❌ Dispositivo #{device.uuid} (#{device.device_type.name}) en #{local.name} FALLÓ: Respuesta JSON inválida."
    rescue StandardError => e
      Rails.logger.error "Error inesperado al enviar datos para dispositivo #{device.uuid}: #{e.message}"
      puts "  [#{Time.current.strftime('%H:%M:%S')}] ❌ Dispositivo #{device.uuid} (#{device.device_type.name}) en #{local.name} FALLÓ debido a error inesperado: #{e.message}"
    end
  end

  # Recupera todos los dispositivos y sus locales asignados
  all_devices_with_locals = Device.includes(:device_type, local_devices: :local)
                                  .map do |device|
                                    current_local_device = device.local_devices.find_by(is_current: true)
                                    [device, current_local_device&.local] if current_local_device
                                  end.compact

  if all_devices_with_locals.empty?
    puts "No se encontraron dispositivos activos en locales para simular actividad. Por favor, ejecuta `rails db:seed` primero."
    exit 0
  end

  puts "\nIniciando simulación para #{all_devices_with_locals.count} dispositivos..."
  puts "Conectando a la API en: #{BASE_API_URL}"
  puts "Presiona Ctrl+C para detener la simulación."

  # Bucle infinito para simular actividad continua de los dispositivos
  loop do
    all_devices_with_locals.each do |device, local|
      sleep_time = rand(1..MAX_INTERACTION_INTERVAL)
      puts "  Próxima actualización para #{device.uuid} en #{sleep_time} segundos..."
      sleep sleep_time

      is_error = rand < ERROR_PROBABILITY
      send_device_data(device, local, is_error)
    end
  end

rescue Interrupt
  puts "\n--- Simulación de Actividad de Dispositivos Detenida ---"
rescue StandardError => e
  Rails.logger.error "Error en el script de simulación: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
  puts "El script de simulación encontró un error. Revisa los logs."
end