func convert_to_js(data):
	var data_type = typeof(data)
	
	match data_type:
		TYPE_DICTIONARY:
			var js_object = JavaScriptBridge.create_object("Object")
			
			for key in data:
				js_object[key] = convert_to_js(data[key])
			
			return js_object
		
		TYPE_ARRAY:
			var js_array = JavaScriptBridge.create_object("Array")
			
			for i in range(data.size()):
				js_array[i] = convert_to_js(data[i])
			
			return js_array
		
		TYPE_STRING:
			return data
		
		TYPE_BOOL:
			return data
		
		TYPE_INT:
			return data
		
		TYPE_FLOAT:
			return data
	
	return null

func convert_to_gd_object(js_data):
	if typeof(js_data) != TYPE_OBJECT:
		return null
	
	var js_item_keys = JavaScriptBridge.get_interface("Object").keys(js_data)
	var item = {}
	for j in range(js_item_keys.length):
		var key = js_item_keys[j]
		item[key] = js_data[key]

	return item
