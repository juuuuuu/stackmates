extends GutTest


func test_private_ipv4_detection() -> void:
	assert_true(NetInfo.is_private_ipv4("10.0.0.1"))
	assert_true(NetInfo.is_private_ipv4("172.16.5.5"))
	assert_true(NetInfo.is_private_ipv4("192.168.1.20"))
	assert_false(NetInfo.is_private_ipv4("172.32.0.1"))
	assert_false(NetInfo.is_private_ipv4("8.8.8.8"))
	assert_false(NetInfo.is_private_ipv4("fe80::1"))
	assert_false(NetInfo.is_private_ipv4(""))


func test_local_ipv4_is_private_or_empty() -> void:
	var address: String = NetInfo.local_ipv4()
	assert_true(address.is_empty() or NetInfo.is_private_ipv4(address))
