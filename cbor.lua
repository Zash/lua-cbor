-- Concise Binary Object Representation (CBOR)
-- RFC 7049

local function softreq(pkg, field)
	local ok, mod = pcall(require, pkg);
	if not ok then return end
	if field then return mod[field]; end
	return mod;
end
local dostring = function (s)
	local ok, f = (loadstring or load)(s);
	if ok then return f(); end
end

local setmetatable = setmetatable;
local getmetatable = getmetatable;
local error = error;
local type = type;
local pairs = pairs;
local s_byte = string.byte;
local s_char = string.char;
local t_concat = table.concat;
local m_floor = math.floor;
local m_abs = math.abs;
local m_huge = math.huge;
local m_max = math.max;
local maxint = math.maxinteger or 9007199254740992;
local minint = math.mininteger or -9007199254740992;
local m_frexp = math.frexp;
local m_type = math.type or function (n) return n % 1 == 0 and n <= maxint and n >= minint and "integer" or "float" end;
local s_pack = string.pack or softreq("struct", "pack");
local b_rshift = softreq("bit32", "rshift") or softreq("bit", "rshift") or
	dostring"return function(a,b) return a>>b end" or
	function (a, b) return m_max(0, m_floor(a / (2^b))); end;

local encoder = {};

local function encode(obj)
	return encoder[type(obj)](obj);
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
		local high = m_floor(num / 2^32);
		num = num % 2^32;
		return s_char(m + 27,
			b_rshift(high, 24) % 0x100,
			b_rshift(high, 16) % 0x100,
			b_rshift(high, 8) % 0x100,
			high % 0x100,
			b_rshift(num, 24) % 0x100,
			b_rshift(num, 16) % 0x100,
			b_rshift(num, 8) % 0x100,
			num % 0x100);
	end
	error "int too large";
end

if s_pack then
	function integer(num, m, fmt)
		m = m or 0;
		if num < 24 then
			fmt, m = ">B", m + num;
		elseif num < 256 then
			fmt, m = ">BB", m + 24;
		elseif num < 65536 then
			fmt, m = ">BI2", m + 25;
		elseif num < 4294967296 then
			fmt, m = ">BI4", m + 26;
		else
			fmt, m = ">BI8", m + 27;
		end
		return s_pack(fmt, m, num);
	end
end

local simple_mt = {};
function simple_mt:__tostring() return self.name or ("simple(%d)"):format(self.value); end
function simple_mt:__tocbor() return self.cbor or integer(self.value, 224); end

local function simple(value, name, cbor)
	if value < 0 or value > 255 then
		error "simple value out of bounds";
	end
	return setmetatable({ value = value, name = name, cbor = cbor }, simple_mt);
end

local tagged_mt = {};
function tagged_mt:__tostring() return ("%d(%s)"):format(self.tag, tostring(self.value)); end
function tagged_mt:__tocbor() return integer(self.tag, 192) .. encode(self.value); end

local function tagged(tag, value)
	return setmetatable({ tag = tag, value = value }, tagged_mt);
end

local null = simple(22, "null"); -- explicit null
local undefined = simple(23, "undefined"); -- undefined or nil
local BREAK = simple(31, "break", "\255");

-- Number types dispatch
function encoder.number(num)
	return encoder[m_type(num)](num);
end

-- Major types 0, 1
function encoder.integer(num)
	if num < 0 then
		return integer(-1-num, 32);
	end
	return integer(num, 0);
end

-- Major type 7
function encoder.float(num)
	local sign = (num > 0 or 1 / num > 0) and 0 or 1
	if num ~= num then
		return "\251\127\255\255\255\255\255\255\255";
	end
	num = m_abs(num)
	if num == m_huge then
		return s_char(251, sign * 2^7 + 2^7 - 1) .. "\240\0\0\0\0\0\0";
	end
	local fraction, exponent = m_frexp(num)
	if fraction == 0 then
		return s_char(251, sign * 2^7) .. "\0\0\0\0\0\0\0";
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

if s_pack then
	function encoder.float(num)
		return s_pack(">bd", 251, num);
	end
end


-- Major type 2 - byte strings
function encoder.bytestring(s)
	return integer(#s, 64) .. s;
end

function encoder.boolean(bool)
	return bool and "\245" or "\244";
end

encoder["nil"] = function() return "\246"; end

function encoder.userdata(ud)
	local mt = debug.getmetatable(ud);
	if mt and mt.__tocbor then
		return mt.__tocbor(ud);
	end
	error "can't encode userdata"
end

function encoder.table(t)
	local mt = getmetatable(t);
	if mt and mt.__tocbor then
		return mt.__tocbor(t);
	end
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

encoder["function"] = function()
	error "can't encode function";
end

local function _readlen(data, mintyp, pos)
	if mintyp <= 0x17 then
		return mintyp, pos+1;
	elseif mintyp <= 0x1b then
		local out = 0;
		pos = pos + 1;
		for i = 1, 2^(mintyp-0x18) do
			out, pos = out * 256 + s_byte(data, pos), pos + 1;
		end
		return out, pos;
	end
end

local function decode(data, pos)
	pos = pos or 1;
	local typ, mintyp = s_byte(data, pos);
	typ, mintyp = b_rshift(typ, 5), typ % 0x20;
	if typ == 0 then
		return _readlen(data, mintyp, pos);
	elseif typ == 1 then
		mintyp, pos = _readlen(data, mintyp, pos);
		return -1 - mintyp, pos;
	elseif typ == 2 or typ == 3 then
		if mintyp == 31 then
			local out, i = {}, 1;
			pos = pos + 1;
			while s_byte(data, pos) ~= 0xff do
				i, out[i], pos = i+1, decode(data, pos);
			end
			return t_concat(out), pos+1;
		end
		mintyp, pos = _readlen(data, mintyp, pos);
		return data:sub(pos, pos+mintyp-1), pos+mintyp;
	elseif typ == 4 then
		local out = {};
		if mintyp == 31 then
			local i = 1;
			pos = pos + 1;
			while s_byte(data, pos) ~= 0xff do
				out[i], pos = decode(data, pos);
				i = i + 1;
			end
			return out, pos + 1;
		end
		mintyp, pos = _readlen(data, mintyp, pos);
		for i = 1, mintyp do
			out[i], pos = decode(data, pos);
		end
		return out, pos;
	elseif typ == 5 then
		local out, key = {};
		if mintyp == 31 then
			pos = pos + 1;
			while s_byte(data, pos) ~= 0xff do
				key, pos = decode(data, pos)
				out[key], pos = decode(data, pos);
			end
			return out, pos + 1;
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
		error(("Decoding major type %d, minor type %d is not implemented"):format(typ or -1, mintyp or -1));
	end
	-- TODO Tagged types and floats
	error(("Decoding major type %d is not implemented"):format(typ));
end

return {
	encode = encode;
	decode = decode;
	type_encoders = encoder;
	null = null;
	undefined = undefined;
	simple = simple;
	tagged = tagged;
};
