class_name GameLocalization
extends RefCounted


static func Text(key: String) -> String:
	return TranslationServer.translate(key)


static func Format(key: String, values: Dictionary) -> String:
	return Text(key).format(values)


static func ItemName(item: ItemData) -> String:
	return "" if item == null else Text(item.Name)


static func ItemDescription(item: ItemData) -> String:
	return "" if item == null else Text(item.Description)
