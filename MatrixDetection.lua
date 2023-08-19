--[[
  Wolfe's Mekanism Induction Matrix Monitor
  Usage: Put computer with code near an Induction Port and a monitor (2x3 array should work fine) and run.
  Configuration: You can add a file called "config" with the options below, or append them to the command when running it via terminal:
    energy_type = 'FE' -- Energy type you want to use
    update_frequency = 1 -- Update frequency, in seconds
    text_scale = 1 -- The text scale on the monitor, use 0.5 if you want to run on less displays
    side_monitor = 'right' -- Hardcodes which side the monitor should be, defaults to auto-detection
    side_inductor = 'back' -- Hardcodes which side the Induction Port should be, defaults to auto-detection
]]

-- 
-- Usage: Put computer near an Induction Port and a monitor , set the sides below and run.

-- Default settings
options = {
  energy_type = 'FE',
  update_frequency = 1,
  text_scale = 1,
}

-- Loads custom options from file (if available)
if fs.exists('config') then
  -- Opens the file for reading
  local handle = fs.open('config')

  -- Reads configs
  raw_options = {}
  local line = handle.readLine()
  while line do
    table.insert(raw_options, line)
    line = handle.readLine()
  end

  -- Sets custom options
  custom_options = string.format('{%s}', table.concat(raw_options, '\n,'))

  -- Closes the handle properly
  handle.close()
end

-- Gets custom settings via arguments
args = {...}
if args and #args > 0 then
  -- Parses custom settings from args
  custom_options = string.format('{%s}', table.concat(args, '\n,'))
end

-- Detects custom options
if custom_options then
  -- Debug only
  print('Running with custom options:')

  -- Makes sure we're dealing with a table to prevent code injection
  if '{' == custom_options:sub(1, 1) then
    -- Parses the object
    custom_options, err = loadstring(string.format('return %s', custom_options))

    -- Handles invalid object
    if not custom_options then
      print('Invalid options:')
      print(err)
    else
      -- Replaces settings
      for k, v in pairs(custom_options()) do
        print(string.format('%s = %s', k, v))
        options[k] = v
      end
    end
  end
end

-- Auto-detects sides

-- Connects to Peripherals
 
-- Queues a new print command to be sent
buffer = {}
function queue (text)
  table.insert(buffer, text)
end
 
-- Queues a new print command with string.format
function queuef (fmt, ...)
  queue(string.format(fmt, ...))
end
 
-- Flushes (prints) buffer content
function queue_flush ()
  -- Clears terminal
  term.clear()
  term.setCursorPos(1, 1)

  -- Writes new data
  print(table.concat(buffer, '\n'))
  buffer = {}
end
 
-- Formats time
function time (secs)
  -- Prepare value
  secs = math.floor(secs)
 
  -- Days
  local weeks = math.floor(secs / 604800)
  secs = secs - (604800 * weeks)
 
  -- Days
  local days = math.floor(secs / 86400)
  secs = secs - (86400 * days)
 
  -- Hours
  local hours = math.floor(secs / 3600)
  secs = secs - (3600 * hours)
 
  -- Minutes
  local mins = math.floor(secs / 60)
  secs = secs - (60 * mins)

  -- If we have more than 72h worth of storage, switch to week, day, hour format
  if weeks > 0 then
    return string.format('%dwk %dd %dh', weeks, days, hours)
  elseif days >= 3 then
    return string.format('%dd %dh', days, hours)
  end
 
  -- Formatting to have trailing zeros on H:MM:SS 
  return string.format('%d:%02d:%02d', hours, mins, secs)
end
 
-- Rounds number
function rnd (val, dec)
  local X = math.pow(10, dec)
  return math.floor(val * X) / X
end
 
-- Converts to percentage
function pct (val, dec)
  return rnd(100 * val, dec or 1) .. '%'
end
 
-- Converts to readable power
function pwr (val, dec)
  local pre = ''
  local suf = ''

  local is_neg = false
  if val < 0 then
    pre = '-'
    is_neg = true
    val = -val
  end
  
  val = energy_function(val)
  
  if val > 1000 then
    suf = 'k'
    val = val / 1000
  end
  
  if val > 1000 then
    suf = 'M'
    val = val / 1000
  end
  
  if val > 1000 then
    suf = 'G'
    val = val / 1000
  end
  
  if val > 1000 then
    suf = 'T'
    val = val / 1000
  end
  
  return string.format('%s%s%s%s', pre, rnd(val, dec or 1), suf, energy_type)
end

-- Checks induction port
function check_connection ()
  return inductor and inductor.getEnergy and inductor.getLastInput
end

-- Detects energy type, sets energy function
energy_type = options.energy_type
energy_function = mekanismEnergyHelper[string.format('joulesTo%s', energy_type)]

-- Function not found, use default Joules and a stub
if not energy_function then
  energy_type = 'J'
  energy_function = function (val) return val end
end

-- Checks if Inductor Port is missing or multiblock not ready
inductor = peripheral.wrap("bottom")
while not check_connection() do
  -- Writes error message
  queue('Ind.Port not found')
  queue('Check connections.')
  queue('Waiting...')

  -- Prints
  queue_flush()
  
  -- Wait for next update
  os.sleep(options.update_frequency)

  -- Tries to detect port
  if not options.side_inductor then
    for _, side in pairs(peripheral.getNames()) do
      -- Tries to find an induction port
      if 'inductionPort' == peripheral.getType(side) then
        options.side_inductor = side
        inductor = peripheral.wrap(options.side_inductor)
      end
    end
  else
    -- Try again on pre-set port
    inductor = peripheral.wrap(options.side_inductor)
  end
end
 
-- Initializes balance
balance = inductor.getEnergy()
-- Make sure to load the rednet library before using it
rednet.open("top")

while true do
  local status, err = pcall(function ()
    -- Main script
    local output = {}
    table.insert(output, 'Ind.Matrix Monitor')
    table.insert(output, '------------------')
    table.insert(output, '')
    table.insert(output, string.format('Power : %s', pwr(inductor.getEnergy())))
    table.insert(output, string.format('Limit : %s', pwr(inductor.getMaxEnergy())))
    table.insert(output, string.format('Charge: %s', pct(inductor.getEnergyFilledPercentage())))
    table.insert(output, '')
    table.insert(output, string.format('Input : %s', pwr(inductor.getLastInput())))
    table.insert(output, string.format('Output: %s', pwr(inductor.getLastOutput())))
    table.insert(output, string.format('Max IO: %s/t', pwr(inductor.getTransferCap())))
    table.insert(output, '')
    -- ... (rest of your output formatting code)

    -- Convert the output to a single string with newlines
    local outputString = table.concat(output, "\n")

    -- Send the output using rednet (replace 123 with the receiver's computer ID)
    rednet.send(6, outputString)
  end)

  -- ... (rest of your error handling code)

  -- Wait before the next iteration
  sleep(options.update_frequency)
end

-- Close the rednet modem when done
rednet.close("top")