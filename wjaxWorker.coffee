# JSON Check Function
isJSON = (str) ->
	try JSON.parse str; catch e then return false;
	return true

# AJAX Worker
AJAX = (options = {}, callback) ->
	# AJAX Start
	xhr = new XMLHttpRequest()

	xhr.onreadystatechange = ->
		if xhr.readyState is 4
			if xhr.status in [0, 200]
				# JSON
				if isJSON xhr.responseText
					finalResponse = JSON.parse xhr.responseText

				# Text
				else
					finalResponse = xhr.responseText

				callback?(null, finalResponse)

	xhr.onerror = -> self.postMessage "ERROR"

	# AJAX Timeout
	xhr.timeout = options.timeout
	
	options.url = "#{options.url}#{options.formData}" if options.method is "GET"
	xhr.open options.method, options.url, true
	xhr.setRequestHeader "Content-Type", "application\/x-www-form-urlencoded"

	# Send Body
	if options.body? and options.method isnt "GET"
		xhr.send options.formData

	else
		xhr.send()

self.addEventListener "message", (e) ->
	options = JSON.parse e.data
	AJAX options, (err, res) ->
		if err
			self.postMessage "ERROR"

		else
			self.postMessage res

		# Destroy Worker After Job Done
		self.close()