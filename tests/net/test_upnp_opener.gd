extends GutTest
## Cycle de vie du mapping UPnP avec un faux gateway qui journalise ses appels.


class FakeGateway:
	extends UpnpGateway
	var calls: Array[String]
	var add_ok: bool = true

	func _init(shared_log: Array[String], ok: bool) -> void:
		calls = shared_log
		add_ok = ok

	func discover() -> bool:
		calls.append("discover")
		return true

	func add_mapping(port: int) -> bool:
		calls.append("add %d" % port)
		return add_ok

	func delete_mapping(port: int) -> bool:
		calls.append("delete %d" % port)
		return true


func before_each() -> void:
	TranslationServer.set_locale("en")


func _opener(add_ok: bool, calls: Array[String]) -> UpnpOpener:
	var opener: UpnpOpener = add_child_autofree(UpnpOpener.new())
	opener.use_thread = false
	opener.gateway_factory = func() -> UpnpGateway: return FakeGateway.new(calls, add_ok)
	return opener


func test_open_adds_the_mapping_and_reports_success() -> void:
	var calls: Array[String] = []
	var opener: UpnpOpener = _opener(true, calls)
	watch_signals(opener)
	opener.open(28015)
	await wait_frames(1)
	assert_signal_emitted_with_parameters(opener, "finished", [true, "UPnP: port opened"])
	assert_eq(calls, ["discover", "add 28015"])


func test_open_failure_message_names_the_port() -> void:
	var calls: Array[String] = []
	var opener: UpnpOpener = _opener(false, calls)
	watch_signals(opener)
	opener.open(28016)
	await wait_frames(1)
	assert_signal_emitted_with_parameters(
		opener, "finished", [false, "UPnP: failed. Open UDP port 28016 on your router."]
	)


func test_close_after_open_deletes_the_mapping() -> void:
	var calls: Array[String] = []
	var opener: UpnpOpener = _opener(true, calls)
	opener.open(28015)
	await wait_frames(1)
	opener.close()
	await wait_frames(1)
	assert_eq(calls, ["discover", "add 28015", "discover", "delete 28015"])


func test_close_without_mapping_does_nothing() -> void:
	var calls: Array[String] = []
	var opener: UpnpOpener = _opener(false, calls)
	opener.open(28015)
	await wait_frames(1)
	opener.close()
	await wait_frames(1)
	assert_eq(calls, ["discover", "add 28015"])


func test_close_requested_during_open_runs_after_it() -> void:
	var calls: Array[String] = []
	var opener: UpnpOpener = _opener(true, calls)
	opener.open(28015)
	opener.close()
	await wait_frames(2)
	assert_eq(calls, ["discover", "add 28015", "discover", "delete 28015"])


func test_open_requested_during_close_runs_after_it_on_its_own_port() -> void:
	var calls: Array[String] = []
	var opener: UpnpOpener = _opener(true, calls)
	watch_signals(opener)
	opener.open(28015)
	await wait_frames(1)
	opener.close()
	opener.open(28016)
	await wait_frames(3)
	assert_eq(calls, ["discover", "add 28015", "discover", "delete 28015", "discover", "add 28016"])
	assert_signal_emit_count(opener, "finished", 2)


func test_open_requested_during_pending_close_runs_last() -> void:
	var calls: Array[String] = []
	var opener: UpnpOpener = _opener(true, calls)
	opener.open(28015)
	opener.close()
	opener.open(28016)
	await wait_frames(3)
	assert_eq(calls, ["discover", "add 28015", "discover", "delete 28015", "discover", "add 28016"])
