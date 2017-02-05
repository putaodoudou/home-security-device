local dht = require("dht")
local adc = require("adc")

local initSensors = function (pins, topics, publish)

	-- init motion detection (PIR)
	global.gpio.mode(pins.motion, global.gpio.INPUT)
	global.gpio.trig(pins.motion, "both", function (level)
		print("Motion: "..level)
		publish(topics.motion, level)
	end)

	-- init humidity and temperature sensor (DHT)
	global.tmr.alarm(1, 30000, 1, function()
		status, temp, humi = dht.read(pins.dht)

		if status == dht.OK then
			publish(topics.tempHum, {
				temperature = temp,
				humidity = humi	
			})
		elseif status == dht.ERROR_CHECKSUM then
			publish(topics.tempHum, nil, "DHT_ERROR_CHECKSUM")
		elseif status == dht.ERROR_TIMEOUT then
			publish(topics.tempHum, nil, "DHT_ERROR_TIMEOUT")
		end
	end)

	-- init gas sensor (MQ-2)
	-- global.tmr.alarm(2, 1200, 1, function ()
	-- 	print(adc.read(0))
	-- end)
end

local initSimulation = function (pins, topics, publish)
	print("Simulating sensors data!")

	-- simulate motion detection
	global.tmr.alarm(0, 5000, 1, function ()
		publish(topics.motion, math.floor(math.random() * 2))
	end)

	-- simulate humidity and temperature sensor
	local dhtErrors = { "DHT_ERROR_CHECKSUM", "DHT_ERROR_TIMEOUT" }
	global.tmr.alarm(1, 30000, 1, function ()
		local error = dhtErrors[math.floor(math.random() * 10)]

		if (error) then publish(topics.tempHum, nil, error)
		else publish(topics.tempHum, {
			temperature = math.floor(math.random() * 100),
			humidity = math.floor(math.random() * 100)
		}) end
	end)
end

return function (config, pins, topics, publish)
	local lastSent = {
		[topics.motion] = {},
		[topics.tempHum] = {}
		-- [topics.gas]
	}

	local optimizedPublish = function (topic, data)
		if (global.cjson.encode(lastSent[topic]) ~= global.cjson.encode(data)) then
			publish(topic, data)
			lastSent[topic] = data
		else
			print('Refused to send data for '..topic..', due to bandwith optimizations')
		end
	end

	local initMethod = ( config.device.simulation ) and initSimulation or initSensors
	initMethod(pins, topics, optimizedPublish)
end