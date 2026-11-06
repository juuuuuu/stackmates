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


## L'IPv4 privée la plus probable du réseau domestique, ou vide.
static func local_ipv4() -> String:
	return pick_local(IP.get_local_addresses())


## Préfère 192.168/16, puis 10/8, puis 172.16/12 (les ponts Docker et les
## VPN y vivent souvent). Vide sans IPv4 privée.
static func pick_local(addresses: PackedStringArray) -> String:
	var best: String = ""
	var best_rank: int = 99
	for address: String in addresses:
		if not is_private_ipv4(address):
			continue
		var rank: int = 2
		if address.begins_with("192.168."):
			rank = 0
		elif address.begins_with("10."):
			rank = 1
		if rank < best_rank:
			best = address
			best_rank = rank
	return best
