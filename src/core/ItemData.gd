class_name ItemData
extends RefCounted

enum ItemType {
	Staff,
	Stone,
	Amulet,
	Material,
	Consumable
}

enum ItemRarity {
	Common,
	Uncommon,
	Rare,
	Epic,
	Legendary
}

var Id: String = ""
var Name: String = ""
var Description: String = ""
var Type: ItemType = ItemType.Material
var Rarity: ItemRarity = ItemRarity.Common

# Combat modifiers
var BaseDamage: int = 0
var AttackSpeedBonus: float = 0.0
var ManaBonus: int = 0
var RegenBonus: float = 0.0
var CritChanceBonus: float = 0.0

var SellValue: int = 0
var StackCount: int = 1
var MaxStack: int = 1
var IconTexturePath: String = ""

func duplicate_item() -> ItemData:
	var copy = ItemData.new()
	copy.Id = Id
	copy.Name = Name
	copy.Description = Description
	copy.Type = Type
	copy.Rarity = Rarity
	copy.BaseDamage = BaseDamage
	copy.AttackSpeedBonus = AttackSpeedBonus
	copy.ManaBonus = ManaBonus
	copy.RegenBonus = RegenBonus
	copy.CritChanceBonus = CritChanceBonus
	copy.SellValue = SellValue
	copy.StackCount = StackCount
	copy.MaxStack = MaxStack
	copy.IconTexturePath = IconTexturePath
	return copy

func to_dict() -> Dictionary:
	return {
		"Id": Id,
		"Name": Name,
		"Description": Description,
		"Type": int(Type),
		"Rarity": int(Rarity),
		"BaseDamage": BaseDamage,
		"AttackSpeedBonus": AttackSpeedBonus,
		"ManaBonus": ManaBonus,
		"RegenBonus": RegenBonus,
		"CritChanceBonus": CritChanceBonus,
		"SellValue": SellValue,
		"StackCount": StackCount,
		"MaxStack": MaxStack,
		"IconTexturePath": IconTexturePath
	}

static func from_dict(d: Dictionary) -> ItemData:
	if d == null or d.is_empty():
		return null
	var item = ItemData.new()
	item.Id = str(d.get("Id", ""))
	item.Name = str(d.get("Name", ""))
	item.Description = str(d.get("Description", ""))
	item.Type = int(d.get("Type", ItemType.Material)) as ItemType
	item.Rarity = int(d.get("Rarity", ItemRarity.Common)) as ItemRarity
	item.BaseDamage = int(d.get("BaseDamage", 0))
	item.AttackSpeedBonus = float(d.get("AttackSpeedBonus", 0.0))
	item.ManaBonus = int(d.get("ManaBonus", 0))
	item.RegenBonus = float(d.get("RegenBonus", 0.0))
	item.CritChanceBonus = float(d.get("CritChanceBonus", 0.0))
	item.SellValue = int(d.get("SellValue", 0))
	item.StackCount = int(d.get("StackCount", 1))
	item.MaxStack = int(d.get("MaxStack", 1))
	item.IconTexturePath = str(d.get("IconTexturePath", ""))
	return item

