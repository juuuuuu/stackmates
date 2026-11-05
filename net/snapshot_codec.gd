class_name SnapshotCodec
extends RefCounted
## Encode et décode un Snapshot en binaire little-endian : u32 tick,
## u8 level_flags, u8 count (0 à 8), puis count fois u8 slot, f32 x, f32 y,
## u8 flags. Taille : 6 + 10 * count octets.

const HEADER_SIZE: int = 6
const PLAYER_SIZE: int = 10


static func encode(s: Snapshot) -> PackedByteArray:
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	buffer.big_endian = false
	buffer.put_u32(s.tick)
	buffer.put_u8(s.level_flags)
	buffer.put_u8(s.slots.size())
	for i: int in s.slots.size():
		buffer.put_u8(s.slots[i])
		buffer.put_float(s.positions[i].x)
		buffer.put_float(s.positions[i].y)
		buffer.put_u8(s.flags[i])
	return buffer.data_array


## Rend null si les octets ne forment pas un snapshot valide.
static func decode(bytes: PackedByteArray) -> Snapshot:
	if bytes.size() < HEADER_SIZE:
		return null
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	buffer.big_endian = false
	buffer.data_array = bytes
	var s: Snapshot = Snapshot.new()
	s.tick = buffer.get_u32()
	s.level_flags = buffer.get_u8()
	var count: int = buffer.get_u8()
	if count > SimConstants.MAX_PLAYERS:
		return null
	if bytes.size() != HEADER_SIZE + PLAYER_SIZE * count:
		return null
	for i: int in count:
		s.slots.append(buffer.get_u8())
		var x: float = buffer.get_float()
		var y: float = buffer.get_float()
		s.positions.append(Vector2(x, y))
		s.flags.append(buffer.get_u8())
	return s
