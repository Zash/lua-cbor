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
local m_ldexp = math.ldexp;
local m_type = math.type or function (n) return n % 1 == 0 and n <= maxint and n >= minint and "integer" or "float" end;
local s_pack = string.pack or softreq("struct", "pack");
local s_unpack = string.unpack or softreq("struct", "unpack");
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

local function read_bytes(fh, len)
	return fh:read(len);
end

local function read_byte(fh)
	return fh:read(1):byte();
end

local function read_length(fh, mintyp)
	if mintyp < 24 then
		return mintyp;
	elseif mintyp < 28 then
		local out = 0;
		for i = 1, 2^(mintyp-24) do
			out = out * 256 + read_byte(fh);
		end
		return out;
	else
		error "invalid length";
	end
end

local decoder = {};

local function read_type(fh)
	local byte = read_byte(fh);
	return b_rshift(byte, 5), byte % 2^5;
end

local function read_object(fh)
	local typ, mintyp = read_type(fh);
	return decoder[typ](fh, mintyp);
end

local function read_integer(fh, mintyp)
	return read_length(fh, mintyp);
end

local function read_negative_integer(fh, mintyp)
	return -1 - read_length(fh, mintyp);
end

local function read_string(fh, mintyp)
	if mintyp ~= 31 then
		return read_bytes(fh, read_length(fh, mintyp));
	end
	local out = {};
	local i = 1;
	local v = read_object(fh);
	while v ~= BREAK do
		out[i], i = v, i+1;
		v = read_object(fh);
	end
	return t_concat(out);
end

local function read_unicode_string(fh, mintyp)
	return read_string(fh, mintyp);
	-- local str = read_string(fh, mintyp);
	-- if have_utf8 and not utf8.len(str) then
		-- TODO How to handle this?
	-- end
	-- return str;
end

local function read_array(fh, mintyp)
	local out = {};
	if mintyp == 31 then
		local i = 1;
		local v = read_object(fh);
		while v ~= BREAK do
			out[i], i = v, i+1;
			v = read_object(fh);
		end
	else
		local len = read_length(fh, mintyp);
		for i = 1, len do
			out[i] = read_object(fh);
		end
	end
	return out;
end

local function read_map(fh, mintyp)
	local out = {};
	local k;
	if mintyp == 31 then
		local i = 1;
		k = read_object(fh);
		while k ~= BREAK do
			out[k], i = read_object(fh), i+1;
			k = read_object(fh);
		end
	else
		local len = read_length(fh, mintyp);
		for i = 1, len do
			k = read_object(fh);
			out[k] = read_object(fh);
		end
	end
	return out;
end

local function read_semantic(fh, mintyp)
	local tag = read_length(fh, mintyp);
	local value = read_object(fh);
	return tagged(tag, value);
end

local function read_half_float(fh)
	local exponent = read_byte(fh);
	local fraction = read_byte(fh);
	local sign = exponent < 128 and 1 or -1; -- sign is highest bit

	fraction = fraction + (exponent * 256) % 1024; -- copy two(?) bits from exponent to fraction
	exponent = b_rshift(exponent, 2) % 32; -- remove sign bit and two low bits from fraction;

	if exponent == 0 then
		return sign * m_ldexp(exponent, -24);
	elseif exponent ~= 31 then
		return sign * m_ldexp(fraction + 1024, exponent - 25);
	elseif fraction == 0 then
		return sign * m_huge;
	else
		return sign == 1 and 0/0 or m_abs(0/0);
	end
end

local function read_float(fh)
	local exponent = read_byte(fh);
	local fraction = read_byte(fh);
	local sign = exponent < 128 and 1 or -1; -- sign is highest bit
	exponent = exponent * 2 % 256 + b_rshift(fraction, 7);
	fraction = fraction % 128;
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);

	if exponent == 0 then
		return sign * m_ldexp(exponent, -149);
	elseif exponent ~= 0xff then
		return sign * m_ldexp(fraction + 2^23, exponent - 150);
	elseif fraction == 0 then
		return sign * m_huge;
	else
		return sign == 1 and 0/0 or m_abs(0/0);
	end
end

local function read_double(fh)
	local exponent = read_byte(fh);
	local fraction = read_byte(fh);
	local sign = exponent < 128 and 1 or -1; -- sign is highest bit

	exponent = exponent %  128 * 16 + b_rshift(fraction, 4);
	fraction = fraction % 16;
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);
	fraction = fraction * 256 + read_byte(fh);

	if exponent == 0 then
		return sign * m_ldexp(exponent, -149);
	elseif exponent ~= 0xff then
		return sign * m_ldexp(fraction + 2^52, exponent - 1075);
	elseif fraction == 0 then
		return sign * m_huge;
	else
		return sign == 1 and 0/0 or m_abs(0/0);
	end
end


if s_unpack then
	function read_float(fh) return s_unpack(">f", read_bytes(fh, 4)) end
	function read_double(fh) return s_unpack(">d", read_bytes(fh, 8)) end
end

local function read_simple(fh, value)
	if value == 24 then
		value = read_byte(fh);
	end
	if value == 20 then
		return false;
	elseif value == 21 then
		return true;
	elseif value == 22 then
		return null;
	elseif value == 23 then
		return undefined;
	elseif value == 25 then
		return read_half_float(fh);
	elseif value == 26 then
		return read_float(fh);
	elseif value == 27 then
		return read_double(fh);
	elseif value == 31 then
		return BREAK;
	end
	return simple(value);
end

decoder[0] = read_integer;
decoder[1] = read_negative_integer;
decoder[2] = read_string;
decoder[3] = read_unicode_string;
decoder[4] = read_array;
decoder[5] = read_map;
decoder[6] = read_semantic;
decoder[7] = read_simple;

local function parse_streaming(s, more)
	local fh = {};
	local buffer, buf_pos;

	if type(more) ~= "function" then
		if more == nil then
			function more()
				error "input too short";
			end
		else
			error(("bad argument #2 to 'parse_streaming' (function expected, got %s)"):format(type(more)));
		end
	end

	function fh:read(bytes)
		if buffer then
			s, buffer = t_concat(buffer), nil;
		end
		if #s - bytes < 0 then
			local ret = more(bytes - #s, fh);
			if ret then self:write(ret); end
			return self:read(bytes);
		end
		local ret = s:sub(1, bytes);
		s = s:sub(bytes+1, -1);
		return ret;
	end

	function fh:write(bytes)
		if buffer then
			buffer[buf_pos], buf_pos = bytes, buf_pos+1;
		else
			buffer, buf_pos = { s, bytes }, 3;
		end
		return #bytes;
	end

	return read_object(fh);
end

return {
	encode = encode;
	decode = parse_streaming;
	decode_file = read_object;
	type_encoders = encoder;
	type_decoders = decoder;
	null = null;
	undefined = undefined;
	simple = simple;
	tagged = tagged;
};
