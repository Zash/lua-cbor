-- Concise Binary Object Representation (CBOR)
-- RFC 7049

local bit = require"bit";
local b_rshift = bit.rshift;
local b_lshift = bit.lshift;
local band = bit.band;
local type = type;
local pairs = pairs;
local s_byte = string.byte;
local s_char = string.char;
local t_concat = table.concat;
local m_floor = math.floor;
local m_abs = math.abs;
local m_huge = math.huge;
local m_frexp = math.frexp;

local types = {};

local null = newproxy(); -- explicit null
debug.setmetatable(null, {
	__tostring = function() return "null"; end
});
local undefined = newproxy();
debug.setmetatable(undefined, {
	__tostring = function() return "undefined"; end
});

local function encode(obj)
	return types[type(obj)](obj);
end

-- Major types 0, 1 and length encoding for others
local function integer(num, m)
	if m == 0 and num < 0 then
		-- negative integer, major type 1
		num, m  = - num - 1, 32
	end
	if num < 24 then
		return s_char(m + num);
	elseif num < 2^8 then
		return s_char(m + 24, num);
	elseif num < 2^16 then
		return s_char(m + 25, b_rshift(num, 8), num % 0x100);
	elseif num < 2^32 then
		return s_char(m + 26,
			b_rshift(num, 24) % 0x100,
			b_rshift(num, 16) % 0x100,
			b_rshift(num, 8) % 0x100,
			num % 0x100);
	elseif num < 2^64 then
		return s_char(m + 27,
			b_rshift(num, 56) % 0x100,
			b_rshift(num, 48) % 0x100,
			b_rshift(num, 40) % 0x100,
			b_rshift(num, 32) % 0x100,
			b_rshift(num, 24) % 0x100,
			b_rshift(num, 16) % 0x100,
			b_rshift(num, 8) % 0x100,
			num % 0x100);
	end
	error "int too large";
end

-- Major type 7
local function float(num)
	local sign = (num > 0 or 1 / num > 0) and 0 or 1
	if num ~= num then
		return "\127\255\255\255\255\255\255\255"
	end
	num = m_abs(num)
	if num == m_huge then
		return s_char(sign * 2^7 + 2^7 - 1) .. "\240\0\0\0\0\0\0"
	end
	local fraction, exponent = m_frexp(num)
	if fraction == 0 then
		return s_char(sign * 2^7) .. "\0\0\0\0\0\0\0"
	end
	fraction = fraction * 2
	exponent = exponent + 2^10 - 2
	if exponent <= 0 then
		fraction = fraction * 2 ^ (exponent - 1)
		exponent = 0
	else
		fraction = fraction - 1
	end
	return s_char(251,
		sign * 2^7 + m_floor(exponent / 2^4) % 2^7,
		exponent % 2^4 * 2^4 +
		m_floor(fraction * 2^4  % 0x100),
		m_floor(fraction * 2^12 % 0x100),
		m_floor(fraction * 2^20 % 0x100),
		m_floor(fraction * 2^28 % 0x100),
		m_floor(fraction * 2^36 % 0x100),
		m_floor(fraction * 2^44 % 0x100),
		m_floor(fraction * 2^52 % 0x100)
	)
end

-- Major types 0, 1 and 7
function types.number(num)
	if num % 1 == 0 and num <= 9007199254740991 and num >= -9007199254740991 then
		-- Major type 0 and 1
		return integer(num, 0);
	end
	return float(num);
end

-- Major type 2 - byte strings
function types.string(s)
	-- TODO Check for UTF-8 and use major type 3
	return integer(#s, 64) .. s;
end

function types.boolean(bool)
	return bool and "\245" or "\244";
end

types["nil"] = function() return "\246"; end

function types.userdata(ud)
	if ud == null then
		return "\246";
	elseif ud == undefined then
		return "\247";
	end
	-- TODO metamethod?
	error "can't encode userdata"
end

function types.table(t)
	local a, m, i, p = { integer(#t, 128) }, { "\191" }, 1, 2;
	local is_a, ve = true;
	for k, v in pairs(t) do
		is_a = is_a and i == k;
		i = i + 1;

		ve = encode(v);
		a[i] = ve;

		m[p], p = encode(k), p + 1;
		m[p], p = ve, p + 1;
	end
	-- m[p] = "\255";
	m[1] = integer(i-1, 160);
	return t_concat(is_a and a or m);
end

types["function"] = function()
	error "can't encode function";
end

local function _readlen(data, mintyp, pos)
	if mintyp <= 0x17 then
		return mintyp, pos+1;
	elseif mintyp <= 0x1b then
		local out = 0;
		pos = pos + 1;
		for i = 1, 2^(mintyp-0x18) do
			out, pos = out * 256 + data:byte(pos), pos + 1;
		end
		return out, pos;
	end
end

local function decode(data, pos)
	pos = pos or 1;
	local typ, mintyp = data:byte(pos);
	typ, mintyp = b_rshift(typ, 5), typ % 0x20;
	if typ == 0 then
		return _readlen(data, mintyp, pos);
	elseif typ == 1 then
		mintyp, pos = _readlen(data, mintyp, pos);
		return -1 - mintyp, pos;
	elseif typ == 2 or typ == 3 then
		mintyp, pos = _readlen(data, mintyp, pos);
		return data:sub(pos, pos+mintyp-1), pos+mintyp;
	elseif typ == 4 then
		local out = {};
		if mintyp == 31 then
			local i = 1;
			while data:byte(pos) ~= 0xff do
				out[i], pos = decode(data, pos);
				i = i + 1;
			end
			return out, pos;
		end
		mintyp, pos = _readlen(data, mintyp, pos);
		for i = 1, mintyp do
			out[i], pos = decode(data, pos);
		end
		return out, pos;
	elseif typ == 5 then
		local out, key = {};
		if mintyp == 31 then
			while data:byte(pos) ~= 0xff do
				key, pos = decode(data, pos)
				out[key], pos = decode(data, pos);
			end
			return out, pos;
		end
		mintyp, pos = _readlen(data, mintyp, pos);
		for i = 1, mintyp do
			key, pos = decode(data, pos)
			out[key], pos = decode(data, pos);
		end
		return out, pos;
	elseif typ == 7 then
		mintyp, pos = _readlen(data, mintyp, pos);
		if mintyp == 20 then
			return false, pos;
		elseif mintyp == 21 then
			return true, pos;
		elseif mintyp == 22 then
			return null, pos;
		elseif mintyp == 23 then
			return undefined, pos;
		end
		error(("Decoding major type %d, minor type %d is not implemented"):format(typ, mintyp));
	end
	-- TODO Tagged types and floats
	error(("Decoding major type %d is not implemented"):format(typ));
end

return {
	encode = encode;
	decode = decode;
	types = types;
	null = null;
	undefined = undefined;
};
