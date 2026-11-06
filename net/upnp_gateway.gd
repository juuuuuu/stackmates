class_name UpnpGateway
extends RefCounted
## Accès à la box par UPnP. Une instance par job, utilisée dans le thread du
## job : discover d'abord, puis add_mapping ou delete_mapping.

const DISCOVER_TIMEOUT_MS: int = 2000
const DESCRIPTION: String = "Stackmates"
const PROTOCOL: String = "UDP"

var _upnp: UPNP


## Vrai si une box UPnP répond. Bloque jusqu'à DISCOVER_TIMEOUT_MS.
func discover() -> bool:
	_upnp = UPNP.new()
	var result: int = _upnp.discover(DISCOVER_TIMEOUT_MS)
	return result == UPNP.UPNP_RESULT_SUCCESS and _upnp.get_device_count() > 0


func add_mapping(port: int) -> bool:
	var result: int = _upnp.add_port_mapping(port, port, DESCRIPTION, PROTOCOL)
	return result == UPNP.UPNP_RESULT_SUCCESS


func delete_mapping(port: int) -> bool:
	return _upnp.delete_port_mapping(port, PROTOCOL) == UPNP.UPNP_RESULT_SUCCESS
