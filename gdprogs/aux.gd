extends Node

var _bitmask = []


func _get_bit(buffer, offset, bit):
	return bool(buffer[offset] & _bitmask[bit])


func _get_bit32(buffer, offset, bit):
	if bit <= 7:
		return bool(buffer[offset+3] & _bitmask[bit])
	
	if bit <= 15:
		return bool(buffer[offset+2] & _bitmask[bit-8])
	
	if bit <= 23:
		return bool(buffer[offset+1] & _bitmask[bit-16])
	
	if bit <= 31:
		return bool(buffer[offset] & _bitmask[bit-24])


func get_f32(buffer, offset):
	var  i = 0
	
	# load as u32 integer (big endian)
	i += buffer[offset+3]
	i += buffer[offset+2] * 256
	i += buffer[offset+1] * 256 * 256
	i += buffer[offset+0] * 256 * 256 * 256
	
	print(i)
	
	# get the sign
	var _sign = 0.0
	if i >> 31 == 1:
		_sign = -1.0
	else:
		_sign = 1.0
	
	var _exponent = (i >> 23) & 0xFFFFFFFF
	_exponent -= 127
	
	var _fraction = 1.0
	var k = 0
	
	for i in range(0,23):
		k = 22 - i
		
		if _get_bit32(buffer, offset, k):
			_fraction += 1.0 / pow(2, i + 1)
	
	print("sign: ", _sign)
	print("exponent: ", _exponent)
	print("fraction: ", _fraction)
	
	return _sign * _fraction * pow(2, _exponent)


func get_i16(buffer, offset):
	var ret = get_u16(buffer, offset)
	if ret >= 0x8000:
		ret -= 0xFFFF+1
	return ret


func get_i32(buffer, offset):
	var ret = get_u32(buffer, offset)
	if ret >= 0x80000000:
		ret -= 0xFFFFFFFF+1
	return ret


func get_u32(buffer, offset):
	var ret = 0
	ret += buffer[offset]
	ret += buffer[offset+1] * 256
	ret += buffer[offset+2] * 256 * 256
	ret += buffer[offset+3] * 256 * 256 * 256
	return ret


func get_u16(buffer, offset):
	var ret = 0
	ret += buffer[offset]
	ret += buffer[offset+1] * 256
	return ret


func get_u8(buffer, offset):
	var ret = buffer[offset]
	return ret


func get_string(data, offset, _max):
	var s = ""
	var c = 0
	
	for i in range(0, _max):
		c = data[offset+i]
		if c == 0:
			return s
		else:
			s += char(c)
	
	return s


func _ready():
	_bitmask.resize(8)
	_bitmask[0] = 0x01
	_bitmask[1] = 0x02
	_bitmask[2] = 0x04
	_bitmask[3] = 0x08
	_bitmask[4] = 0x10
	_bitmask[5] = 0x20
	_bitmask[6] = 0x40
	_bitmask[7] = 0x80
	