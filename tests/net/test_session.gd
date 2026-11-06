extends GutTest

const UNREACHABLE_PORT: int = 1


func _session() -> Session:
	var session: Session = add_child_autofree(Session.new())
	watch_signals(session)
	return session


func test_enet_accepts_more_peers_than_players_so_the_handshake_refuses() -> void:
	# Le refus "Game is full" vient du handshake : ENet ne doit pas bloquer avant.
	assert_gt(Session.ENET_MAX_CLIENTS, SimConstants.MAX_PLAYERS)


func test_stale_join_timeout_is_ignored_after_a_new_join() -> void:
	var session: Session = _session()
	assert_eq(session.join("127.0.0.1", UNREACHABLE_PORT, "Ju"), OK)
	session.leave()
	assert_eq(session.join("127.0.0.1", UNREACHABLE_PORT, "Ju"), OK)
	session._on_join_timeout(1)
	assert_signal_not_emitted(session, "join_failed")
	session._on_join_timeout(2)
	assert_signal_emitted_with_parameters(session, "join_failed", [Session.REASON_TIMEOUT])
	session.leave()


func test_protocol_version_bumped_for_milestone_1() -> void:
	# Nouveaux RPC et nouveaux flags de snapshot : un client v0.0.1 doit être refusé.
	assert_eq(Session.PROTOCOL_VERSION, 2)
