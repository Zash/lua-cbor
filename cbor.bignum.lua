-- Bignum support using luaossl
local cbor = require "cbor";
local bignum = require "openssl.bignum";

local big_zero = bignum.new(0);
local big_negatives_one = bignum.new(-1);

local function bignum_to_cbor(n)
	local tag = 2;
	if n < big_zero then
		tag = 3;
		n = big_negatives_one - n;
	end
	local as_binary = n:tobin();
	return cbor.type_encoders.table(cbor.tagged(tag, as_binary));
end

bignum.interpose("__tocbor", bignum_to_cbor);

local function tagged2_to_bignum(value)
	local n = bignum.new(0);
	for i = 1, #value do
		n = n:shl(8);
		n = n + value:byte(i);
	end
	return n;
end

if bignum.fromBinary then
	tagged2_to_bignum = bignum.fromBinary;
end

local function tagged3_to_bignum(value)
	return big_negatives_one - tagged2_to_bignum(value);
end

local function tagged_to_bignum(tagged)
	if tagged.tag == 2 then
		return tagged2_to_bignum(tagged.value);
	elseif tagged.tag == 3 then
		return tagged3_to_bignum(tagged.value);
	else
		return nil, "not-a-bignum";
	end
end

if cbor.tagged_decoders then
	cbor.tagged_decoders[2] = tagged2_to_bignum;
	cbor.tagged_decoders[3] = tagged3_to_bignum;
end

return {
	decode = tagged_to_bignum;
}
