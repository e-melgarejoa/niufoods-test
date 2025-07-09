# db/seeds.rb
require 'securerandom' # Para generar UUIDs
require 'time' # Para Time.iso8601

puts "--- Seeding your Device Management App Database ---"

# --- 1. Create Device Types ---
puts "1. Creating Device Types..."
device_types_data = [
  { name: 'Kiosk', description: 'Interactive public display terminals.' },
  { name: 'Sensor', description: 'Environmental or operational data collection units.' },
  { name: 'POS Terminal', description: 'Point of Sale systems for transactions.' },
  { name: 'Digital Signage', description: 'Displays for advertising and information.' },
  { name: 'IoT Gateway', description: 'Connects IoT devices to the cloud.' },
  { name: 'Printer', description: 'Printers for various documents.' }
]

device_types_data.each do |data|
  DeviceType.find_or_create_by!(name: data[:name]) do |dt|
    dt.description = data[:description]
    dt.active = true
  end
  puts "   - Created/Found DeviceType: #{data[:name]}"
end

# Store them for easy access
kiosk_type = DeviceType.find_by(name: 'Kiosk')
sensor_type = DeviceType.find_by(name: 'Sensor')
pos_type = DeviceType.find_by(name: 'POS Terminal')
digital_signage_type = DeviceType.find_by(name: 'Digital Signage')
printer_type = DeviceType.find_by(name: 'Printer')


# --- 2. Create Locals (Locations) ---
puts "\n2. Creating Locals..."
locals_data = [
  { name: 'Santiago Downtown', address: 'Av. Libertador Bernardo O\'Higgins 100', city: 'Santiago', region: 'RM' },
  { name: 'Providencia North', address: 'Av. Providencia 2000', city: 'Providencia', region: 'RM' },
  { name: 'Las Condes East', address: 'Av. Apoquindo 5000', city: 'Las Condes', region: 'RM' },
  { name: 'Valparaíso Port', address: 'Plaza Sotomayor 1', city: 'Valparaíso', region: 'Valparaíso' },
  { name: 'Concepción City Center', address: 'Caupolicán 500', city: 'Concepción', region: 'Biobío' },
  { name: 'Antofagasta Plaza', address: 'Calle Prat 800', city: 'Antofagasta', region: 'Antofagasta' }
]

locals_data.each do |data|
  Local.find_or_create_by!(name: data[:name]) do |l|
    l.address = data[:address]
    l.city = data[:city]
    l.region = data[:region]
    # 'postal_code' and 'phone' fields are not in current schema.rb for Locals
    # l.postal_code = data[:postal_code] # REMOVED
    # l.phone = data[:phone]             # REMOVED
  end
  puts "   - Created/Found Local: #{data[:name]}"
end

# Store them for easy access
santiago_downtown = Local.find_by(name: 'Santiago Downtown')
providencia_north = Local.find_by(name: 'Providencia North')
las_condes_east = Local.find_by(name: 'Las Condes East')
valparaiso_port = Local.find_by(name: 'Valparaíso Port')
concepcion_city = Local.find_by(name: 'Concepción City Center')
antofagasta_plaza = Local.find_by(name: 'Antofagasta Plaza')


# --- 3. Create Devices ---
puts "\n3. Creating Devices..."
devices_data = [
  { uuid: 'K-SCL-001', name: 'Kiosk DT 001', device_type: kiosk_type, manufacturer: 'GlobalKiosk', model: 'M-Pro', serial_number: 'K-001-XYZ', firmware_version: '1.0.0' },
  { uuid: 'K-SCL-002', name: 'Kiosk PV 002', device_type: kiosk_type, manufacturer: 'GlobalKiosk', model: 'M-Lite', serial_number: 'K-002-ABC', firmware_version: '1.0.0' },
  { uuid: 'SEN-SCL-001', name: 'Temp Sensor 001', device_type: sensor_type, manufacturer: 'EnvSense', model: 'T-Plus', serial_number: 'SEN-001-DEF', firmware_version: '1.0.0' },
  { uuid: 'POS-VAP-001', name: 'POS Terminal 001', device_type: pos_type, manufacturer: 'CashFlow', model: 'P-100', serial_number: 'POS-001-GHI', firmware_version: '1.0.0' },
  { uuid: 'DS-CON-001', name: 'Digital Signage 001', device_type: digital_signage_type, manufacturer: 'Visuals', model: 'V-Max', serial_number: 'DS-001-JKL', firmware_version: '1.0.0' },
  { uuid: 'K-SCL-003', name: 'Kiosk LC 003', device_type: kiosk_type, manufacturer: 'GlobalKiosk', model: 'M-Pro', serial_number: 'K-003-MNO', firmware_version: '1.0.0' },
  { uuid: 'SEN-SCL-002', name: 'Humidity Sensor 002', device_type: sensor_type, manufacturer: 'EnvSense', model: 'H-Pro', serial_number: 'SEN-002-PQR', firmware_version: '1.0.0' },
  { uuid: 'POS-SCL-002', name: 'POS Terminal 002', device_type: pos_type, manufacturer: 'CashFlow', model: 'P-100', serial_number: 'POS-002-STU', firmware_version: '1.0.0' },
  { uuid: 'PRT-ANT-001', name: 'Receipt Printer 001', device_type: printer_type, manufacturer: 'PrintFast', model: 'RP-200', serial_number: 'PRT-001-VWX', firmware_version: '1.0.0' }
]

devices_data.each do |data|
  Device.find_or_create_by!(uuid: data[:uuid]) do |d|
    d.name = data[:name]
    d.device_type = data[:device_type]
    d.manufacturer = data[:manufacturer]
    d.model = data[:model]
    d.serial_number = data[:serial_number]
    d.firmware_version = data[:firmware_version]
    d.last_connection_at = Time.current - rand(1..30).days # Simulate recent activity
    d.active = true # Set active to true as per model default behavior
  end
  puts "   - Created/Found Device: #{data[:uuid]}"
end

# Store them for easy access
device_kiosk_scl_001 = Device.find_by(uuid: 'K-SCL-001')
device_kiosk_scl_002 = Device.find_by(uuid: 'K-SCL-002')
device_sensor_scl_001 = Device.find_by(uuid: 'SEN-SCL-001')
device_pos_vap_001 = Device.find_by(uuid: 'POS-VAP-001')
device_ds_con_001 = Device.find_by(uuid: 'DS-CON-001')
device_kiosk_scl_003 = Device.find_by(uuid: 'K-SCL-003')
device_sensor_scl_002 = Device.find_by(uuid: 'SEN-SCL-002')
device_pos_scl_002 = Device.find_by(uuid: 'POS-SCL-002')
device_prt_ant_001 = Device.find_by(uuid: 'PRT-ANT-001')


# --- 4. Assign Devices to Locals (LocalDevice records) ---
puts "\n4. Assigning Devices to Locals..."

# Helper to assign a device to a local, handling is_current logic
def assign_device_to_local(device, local, assigned_from = nil)
  # Deactivate any previous current assignments for this device first
  device.local_devices.where(is_current: true).each do |ld|
    ld.update!(is_current: false, assigned_until: Time.current)
  end

  # Create or find the new current assignment
  LocalDevice.create!(
    device: device,
    local: local,
    assigned_from: assigned_from || Time.current,
    assigned_until: nil, # No end date for current assignment
    is_current: true
  )
  puts "   - Assigned #{device.name} (UUID: #{device.uuid}) to #{local.name}"
rescue ActiveRecord::RecordInvalid => e
  puts "   - ERROR assigning #{device.name} to #{local.name}: #{e.message}"
end


# Assign devices to locals
assign_device_to_local(device_kiosk_scl_001, santiago_downtown, Time.current - 1.year) # Been there a while
assign_device_to_local(device_sensor_scl_001, santiago_downtown, Time.current - 6.months)

assign_device_to_local(device_kiosk_scl_002, providencia_north, Time.current - 3.months)
assign_device_to_local(device_pos_scl_002, providencia_north, Time.current - 2.months)

assign_device_to_local(device_kiosk_scl_003, las_condes_east, Time.current - 1.month)
assign_device_to_local(device_sensor_scl_002, las_condes_east, Time.current - 15.days)

assign_device_to_local(device_pos_vap_001, valparaiso_port, Time.current - 9.months)
assign_device_to_local(device_ds_con_001, concepcion_city, Time.current - 4.months)
assign_device_to_local(device_prt_ant_001, antofagasta_plaza, Time.current - 2.months)


# --- 5. Simulate Device API Requests and Queue Workers ---
# Note: These jobs will only run if Sidekiq process is active.
puts "\n5. Simulating initial DeviceApiRequests and queuing DeviceUpdateJob jobs..."

# Helper for queuing updates
def queue_device_update(device, payload)
  api_request = device.device_api_requests.create!(
    request_payload: payload,
    api_endpoint: '/api/v1/devices/update_status',
    status: :pending, # Default status from model
    sidekiq_job_id: SecureRandom.hex(12) # Simulate a Sidekiq job ID
  )
  DeviceUpdateJob.perform_async(api_request.id)
  puts "   - Queued update for #{device.name} (UUID: #{device.uuid})"
end

# For Kiosk DT 001 in Santiago Downtown - Operative
payload_kiosk_001 = {
  "firmware_version": "1.0.1",
  "battery_level": 88,
  "temperature": 22.1,
  "operational_status": "operative",
  "sync_time": (Time.current - 5.minutes).iso8601
}
queue_device_update(device_kiosk_scl_001, payload_kiosk_001)

# For POS Terminal 001 in Valparaíso - Operative
payload_pos_001 = {
  "firmware_version": "1.0.0",
  "connection_status": "online",
  "last_transaction_at": (Time.current - 10.minutes).iso8601,
  "operational_status": "operative",
  "sync_time": (Time.current - 3.minutes).iso8601
}
queue_device_update(device_pos_vap_001, payload_pos_001)

# For Digital Signage 001 in Concepción - Warning (low memory)
payload_ds_001_warning = {
  "firmware_version": "1.0.0",
  "memory_usage_percent": 95,
  "operational_status": "warning",
  "sync_time": (Time.current - 8.minutes).iso8601
}
queue_device_update(device_ds_con_001, payload_ds_001_warning)

# For Kiosk LC 003 in Las Condes - Trouble (offline)
payload_kiosk_003_trouble = {
  "firmware_version": "1.0.0",
  "network_status": "offline",
  "last_online_at": (Time.current - 2.hours).iso8601,
  "operational_status": "trouble",
  "sync_time": (Time.current - 15.minutes).iso8601
}
queue_device_update(device_kiosk_scl_003, payload_kiosk_003_trouble)

# For Receipt Printer 001 in Antofagasta - In Maintenance
payload_printer_001_maintenance = {
  "firmware_version": "1.0.0",
  "service_due": true,
  "operational_status": "in_maintenance",
  "sync_time": (Time.current - 20.minutes).iso8601
}
queue_device_update(device_prt_ant_001, payload_printer_001_maintenance)


puts "\n--- Database Seeding Complete! ---"
puts "Remember to run Sidekiq in a separate process for the simulated jobs to execute."
puts "Check http://localhost:3000/sidekiq for job status."