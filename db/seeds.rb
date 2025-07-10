# db/seeds.rb
require 'securerandom'
require 'time'

puts "--- Seeding your Device Management App Database ---"

# --- 1. Device Types ---
puts "1. Creating Device Types..."
device_types_data = [
  { name: 'Kiosk', description: 'Interactive public display terminals.' },
  { name: 'Sensor', description: 'Environmental or operational data collection units.' },
  { name: 'POS Terminal', description: 'Point of Sale systems for transactions.' },
  { name: 'Digital Signage', description: 'Displays for advertising and information.' },
  { name: 'IoT Gateway', description: 'Connects IoT devices to the cloud.' },
  { name: 'Printer', description: 'Printers for various documents.' }
]
device_types = device_types_data.map do |data|
  DeviceType.find_or_create_by!(name: data[:name]) do |dt|
    dt.description = data[:description]
    dt.active = true
  end
end
puts "   - Device Types seeded: #{device_types.map(&:name).join(', ')}"

# --- 2. Locals ---
puts "\n2. Creating Locals..."
locals_data = [
  { name: 'Santiago Downtown', address: 'Av. Libertador Bernardo O\'Higgins 100', city: 'Santiago', region: 'RM', operational_status: 0 },
  { name: 'Providencia North', address: 'Av. Providencia 2000', city: 'Providencia', region: 'RM', operational_status: 0 },
  { name: 'Las Condes East', address: 'Av. Apoquindo 5000', city: 'Las Condes', region: 'RM', operational_status: 0 },
  { name: 'Valparaíso Port', address: 'Plaza Sotomayor 1', city: 'Valparaíso', region: 'Valparaíso', operational_status: 0 },
  { name: 'Concepción City Center', address: 'Caupolicán 500', city: 'Concepción', region: 'Biobío', operational_status: 0 },
  { name: 'Antofagasta Plaza', address: 'Calle Prat 800', city: 'Antofagasta', region: 'Antofagasta', operational_status: 0 }
]
locals = locals_data.map do |data|
  Local.find_or_create_by!(name: data[:name]) do |l|
    l.address = data[:address]
    l.city = data[:city]
    l.region = data[:region]
    l.operational_status = data[:operational_status]
  end
end
puts "   - Locals seeded: #{locals.map(&:name).join(', ')}"

# --- 3. Devices ---
puts "\n3. Creating Devices..."
device_types_by_name = device_types.index_by(&:name)
devices_data = [
  { uuid: 'K-SCL-001', name: 'Kiosk DT 001', device_type: device_types_by_name['Kiosk'], manufacturer: 'GlobalKiosk', model: 'M-Pro', serial_number: 'K-001-XYZ', firmware_version: '1.0.0' },
  { uuid: 'K-SCL-002', name: 'Kiosk PV 002', device_type: device_types_by_name['Kiosk'], manufacturer: 'GlobalKiosk', model: 'M-Lite', serial_number: 'K-002-ABC', firmware_version: '1.0.0' },
  { uuid: 'SEN-SCL-001', name: 'Temp Sensor 001', device_type: device_types_by_name['Sensor'], manufacturer: 'EnvSense', model: 'T-Plus', serial_number: 'SEN-001-DEF', firmware_version: '1.0.0' },
  { uuid: 'POS-VAP-001', name: 'POS Terminal 001', device_type: device_types_by_name['POS Terminal'], manufacturer: 'CashFlow', model: 'P-100', serial_number: 'POS-001-GHI', firmware_version: '1.0.0' },
  { uuid: 'DS-CON-001', name: 'Digital Signage 001', device_type: device_types_by_name['Digital Signage'], manufacturer: 'Visuals', model: 'V-Max', serial_number: 'DS-001-JKL', firmware_version: '1.0.0' },
  { uuid: 'K-SCL-003', name: 'Kiosk LC 003', device_type: device_types_by_name['Kiosk'], manufacturer: 'GlobalKiosk', model: 'M-Pro', serial_number: 'K-003-MNO', firmware_version: '1.0.0' },
  { uuid: 'SEN-SCL-002', name: 'Humidity Sensor 002', device_type: device_types_by_name['Sensor'], manufacturer: 'EnvSense', model: 'H-Pro', serial_number: 'SEN-002-PQR', firmware_version: '1.0.0' },
  { uuid: 'POS-SCL-002', name: 'POS Terminal 002', device_type: device_types_by_name['POS Terminal'], manufacturer: 'CashFlow', model: 'P-100', serial_number: 'POS-002-STU', firmware_version: '1.0.0' },
  { uuid: 'PRT-ANT-001', name: 'Receipt Printer 001', device_type: device_types_by_name['Printer'], manufacturer: 'PrintFast', model: 'RP-200', serial_number: 'PRT-001-VWX', firmware_version: '1.0.0' }
]
devices = devices_data.map do |data|
  Device.find_or_create_by!(uuid: data[:uuid]) do |d|
    d.name = data[:name]
    d.device_type = data[:device_type]
    d.manufacturer = data[:manufacturer]
    d.model = data[:model]
    d.serial_number = data[:serial_number]
    d.firmware_version = data[:firmware_version]
    d.last_connection_at = Time.current - rand(1..30).days
    d.active = true
  end
end
puts "   - Devices seeded: #{devices.map(&:uuid).join(', ')}"

# --- 4. Device Updates ---
puts "\n4. Creating DeviceUpdates for each Device..."
devices.each do |device|
  DeviceUpdate.find_or_create_by!(device: device) do |du|
    du.last_update_status = 1
    du.operational_status = 0
    du.last_updated_at = device.last_connection_at
    du.last_sync_time = device.last_connection_at
    du.current_firmware_version = device.firmware_version
    du.desired_firmware_version = device.firmware_version
  end
  puts "   - DeviceUpdate for #{device.uuid}"
end

# --- 5. Assign Devices to Locals ---
puts "\n5. Assigning Devices to Locals..."
assignments = [
  { device_uuid: 'K-SCL-001', local_name: 'Santiago Downtown', assigned_from: Time.current - 1.year },
  { device_uuid: 'SEN-SCL-001', local_name: 'Santiago Downtown', assigned_from: Time.current - 6.months },
  { device_uuid: 'K-SCL-002', local_name: 'Providencia North', assigned_from: Time.current - 3.months },
  { device_uuid: 'POS-SCL-002', local_name: 'Providencia North', assigned_from: Time.current - 2.months },
  { device_uuid: 'K-SCL-003', local_name: 'Las Condes East', assigned_from: Time.current - 1.month },
  { device_uuid: 'SEN-SCL-002', local_name: 'Las Condes East', assigned_from: Time.current - 15.days },
  { device_uuid: 'POS-VAP-001', local_name: 'Valparaíso Port', assigned_from: Time.current - 9.months },
  { device_uuid: 'DS-CON-001', local_name: 'Concepción City Center', assigned_from: Time.current - 4.months },
  { device_uuid: 'PRT-ANT-001', local_name: 'Antofagasta Plaza', assigned_from: Time.current - 2.months }
]
assignments.each do |a|
  device = Device.find_by!(uuid: a[:device_uuid])
  local = Local.find_by!(name: a[:local_name])
  # Deactivate previous assignments
  device.local_devices.where(is_current: true).update_all(is_current: false, assigned_until: Time.current)
  # Create new assignment
  LocalDevice.create!(
    device: device,
    local: local,
    assigned_from: a[:assigned_from],
    assigned_until: nil,
    is_current: true
  )
  puts "   - Assigned #{device.name} to #{local.name}"
end

# --- 6. Simulate Device API Requests and Queue Workers ---
puts "\n6. Simulating DeviceApiRequests and queuing DeviceUpdateJob jobs..."

def queue_device_update(device, payload)
  api_request = device.device_api_requests.create!(
    request_payload: payload,
    api_endpoint: '/api/v1/devices/update_status',
    status: :pending,
    sidekiq_job_id: SecureRandom.hex(12)
  )
  DeviceUpdateJob.perform_async(api_request.id) if defined?(DeviceUpdateJob)
  puts "   - Queued update for #{device.name} (UUID: #{device.uuid})"
end

# Example payloads (igual que antes)
queue_device_update(Device.find_by(uuid: 'K-SCL-001'), {
  firmware_version: "1.0.1",
  battery_level: 88,
  temperature: 22.1,
  operational_status: "operative",
  sync_time: (Time.current - 5.minutes).iso8601
})
queue_device_update(Device.find_by(uuid: 'POS-VAP-001'), {
  firmware_version: "1.0.0",
  connection_status: "online",
  last_transaction_at: (Time.current - 10.minutes).iso8601,
  operational_status: "operative",
  sync_time: (Time.current - 3.minutes).iso8601
})
queue_device_update(Device.find_by(uuid: 'DS-CON-001'), {
  firmware_version: "1.0.0",
  memory_usage_percent: 95,
  operational_status: "warning",
  sync_time: (Time.current - 8.minutes).iso8601
})
queue_device_update(Device.find_by(uuid: 'K-SCL-003'), {
  firmware_version: "1.0.0",
  network_status: "offline",
  last_online_at: (Time.current - 2.hours).iso8601,
  operational_status: "trouble",
  sync_time: (Time.current - 15.minutes).iso8601
})
queue_device_update(Device.find_by(uuid: 'PRT-ANT-001'), {
  firmware_version: "1.0.0",
  service_due: true,
  operational_status: "in_maintenance",
  sync_time: (Time.current - 20.minutes).iso8601
})

puts "\n--- Database Seeding Complete! ---"
