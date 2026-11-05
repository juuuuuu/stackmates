extends GutTest


func test_validate_accepts_valid_join() -> void:
	assert_eq(Roster.new().validate_join(1, 1, "Ju", false), "")


func test_validate_refuses_version_first() -> void:
	assert_eq(Roster.new().validate_join(2, 1, "", true), Roster.REASON_VERSION)


func test_validate_refuses_in_progress() -> void:
	assert_eq(Roster.new().validate_join(1, 1, "Ju", true), Roster.REASON_IN_PROGRESS)


func test_validate_refuses_full() -> void:
	var r: Roster = Roster.new()
	for i: int in 8:
		r.add(100 + i, "P%d" % i)
	assert_eq(r.validate_join(1, 1, "Ju", false), Roster.REASON_FULL)
	assert_eq(r.add(200, "Late"), -1)
	assert_eq(r.size(), 8)


func test_validate_refuses_bad_names() -> void:
	assert_eq(Roster.new().validate_join(1, 1, "", false), Roster.REASON_BAD_NAME)
	assert_eq(Roster.new().validate_join(1, 1, "abcdefghijklm", false), Roster.REASON_BAD_NAME)
	assert_eq(Roster.new().validate_join(1, 1, "abcdefghijkl", false), "")


func test_add_gives_lowest_free_slot() -> void:
	var r: Roster = Roster.new()
	assert_eq(r.add(1, "Host"), 1)
	assert_eq(r.add(50, "A"), 2)
	assert_eq(r.add(51, "B"), 3)
	assert_eq(r.remove_peer(50), 2)
	assert_eq(r.add(52, "C"), 2)
	assert_eq(r.slots(), [1, 2, 3] as Array[int])
	assert_eq(r.name_of(2), "C")
	assert_eq(r.peer_of(2), 52)
	assert_eq(r.slot_of(999), -1)
	assert_eq(r.remove_peer(999), -1)


func test_dict_round_trip() -> void:
	var r: Roster = Roster.new()
	r.add(1, "Host")
	r.add(7, "Guest")
	var copy: Roster = Roster.new()
	copy.apply_dict(r.to_dict())
	assert_eq(copy.slots(), [1, 2] as Array[int])
	assert_eq(copy.name_of(2), "Guest")
