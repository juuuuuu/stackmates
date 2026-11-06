class_name NetInfo
extends RefCounted
## L'adresse IPv4 locale de cette machine, pour la montrer au host.


## Vrai pour une IPv4 privée : 10/8, 172.16/12, 192.168/16.
static func is_private_ipv4(address: String) -> bool:
	var parts: PackedStringArray = address.split(".")
	if parts.size() != 4:
		return false
	var octets: Array[int] = []
	for part: String in parts:
		if not part.is_valid_int():
			return false
		var value: int = part.to_int()
		if value < 0 or value > 255:
			return false
		octets.append(value)
	if octets[0] == 10:
		return true
	if octets[0] == 172 and octets[1] >= 16 and octets[1] <= 31:
		return true
	return octets[0] == 192 and octets[1] == 168


## La première IPv4 privée des interfaces, ou vide.
static func local_ipv4() -> String:
	for address: String in IP.get_local_addresses():
		if is_private_ipv4(address):
			return address
	return ""
