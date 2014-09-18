###
WJAX Library (AJAX Wrapper for REST API with Web Workers Support)

AJAX({
  method: "GET"   (default: "GET")
  url: "http://api.briztime.com/users/123"   (required)
  body: { token: "123" }   (default: null)
  cache: false   (default: false)
  error: "error message to show"   (default: "ERROR: AJAX REQUEST")
  timeout: 15000   (default: 15 seconds)
}, function(err, response) {
  response type is either "text" or "JSON" (Auto-Detect)
});

<Simple GET>
AJAX("http://api.briztime.com/users", function(response) {
  // response on callback
});

###


# JSON Check Function
isJSON = (str) ->
	try JSON.parse str; catch e then return false;
	return true

# nextTick
nextTick = (callback) ->
	setTimeout ->
		callback?()
	, 0

# WJAX
window.WJAX = (options = {}, callback) ->
	# Handle Options for Simple GET
	options = url: options if typeof options is "string"

	# Method Validation
	if options.method?
		methods = ["GET", "POST", "PUT", "DELETE"]
		options.method = options.method.toUpperCase()
		methodIsOK = options.method in methods

		if not methodIsOK
			console.warn "Method should be 'GET', 'POST', 'PUT', 'DELETE'"
			return

	# Default Method is "GET"
	else
		options.method = "GET"

	# Default 15 Seconds Timeout
	options.timeout = 15 * 1000 unless options.timeout?

	# Default Body
	options.body = null unless options.body?

	# Default Cache Strategy
	options.cache = false unless options.cache? and typeof options.cache is "boolean"

	# Default Error Message
	unless options.error?
		options.error = "ERROR: AJAX REQUEST"

	# URL is Required
	unless options.url?
		console.warn "URL should be given for an AJAX call"
		return

	# Create Body Element
	options.formData = ""
	if options.body?
		if isJSON JSON.stringify(options.body)
			options.formData = []
			bodyKeys = Object.keys options.body
			for key in bodyKeys
				options.formData.push "#{key}=#{options.body[key]}"

			if options.jsonp?
				jsonpName = "callback#{new Date().getTime()}"
				options.formData.push "#{options.jsonp}=#{jsonpName}"

			options.formData = options.formData.join("&")
			options.formData = "?#{options.formData}" if options.method is "GET"

		else
			console.warn "body should be a JSON"
			return

	if options.method is "GET" and options.jsonp?
		jsonpElement = document.createElement "script"
		jsonpElement.src = "#{options.url}#{options.formData}"
		document.getElementsByTagName("head")[0].appendChild jsonpElement

		window[jsonpName] = (data) ->
			# JSON
			if isJSON data
				finalResponse = JSON.parse data

			# Text
			else
				finalResponse = data

			callback?(null, finalResponse)

	# WebWorkers AJAX Call
	else if Modernizr.webworkers and options.cache is false
		worker = new Worker "./wjaxWorker.js"

		worker.addEventListener "message", (e) ->
			# Error
			if e.data is "ERROR"
				callback?(new Error "#{options.error}")

			else
				# JSON
				if isJSON e.data
					finalResponse = JSON.parse e.data

				# Text
				else
					finalResponse = e.data

				callback?(null, finalResponse)

		worker.postMessage JSON.stringify(options)

	# Non WebWorkers AJAX Call
	else
		# AJAX Start
		xhr = new XMLHttpRequest()

		xhr.onreadystatechange = ->
			if xhr.readyState is 4 and xhr.status in [0, 200]
				# JSON
				if isJSON xhr.responseText
					finalResponse = JSON.parse xhr.responseText

				# Text
				else
					finalResponse = xhr.responseText

				nextTick -> callback?(null, finalResponse)

		xhr.onerror = -> callback?(new Error "#{options.error}")

		# AJAX Timeout
		xhr.timeout = options.timeout

		# Handle Cacheness of URL
		options.url = "#{options.url}#{options.formData}" if options.method is "GET"
		cacheSuffix = if (/\?/).test(options.url) then "&" else "?"
		cacheSuffix = "#{cacheSuffix}cache=#{new Date().getTime()}"
		options.url = "#{options.url}#{cacheSuffix}" if not options.cache
		
		xhr.open options.method, options.url, true
		xhr.setRequestHeader "Content-Type", "application\/x-www-form-urlencoded"

		# Send Body
		if options.body? and options.method isnt "GET"
			xhr.send options.formData

		else
			xhr.send()
