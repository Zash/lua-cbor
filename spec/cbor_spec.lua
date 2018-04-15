local cbor = require"cbor";
describe("cbor.decode", function ()
	it("AA==", function()
		assert.are.same(0, cbor.decode("\000"))
	end);

	it("AA==", function()
		assert.are.equal("\000", cbor.encode(cbor.decode("\000")))
	end);

	it("AQ==", function()
		assert.are.same(1, cbor.decode("\001"))
	end);

	it("AQ==", function()
		assert.are.equal("\001", cbor.encode(cbor.decode("\001")))
	end);

	it("Cg==", function()
		assert.are.same(10, cbor.decode("\n"))
	end);

	it("Cg==", function()
		assert.are.equal("\n", cbor.encode(cbor.decode("\n")))
	end);

	it("Fw==", function()
		assert.are.same(23, cbor.decode("\023"))
	end);

	it("Fw==", function()
		assert.are.equal("\023", cbor.encode(cbor.decode("\023")))
	end);

	it("GBg=", function()
		assert.are.same(24, cbor.decode("\024\024"))
	end);

	it("GBg=", function()
		assert.are.equal("\024\024", cbor.encode(cbor.decode("\024\024")))
	end);

	it("GBk=", function()
		assert.are.same(25, cbor.decode("\024\025"))
	end);

	it("GBk=", function()
		assert.are.equal("\024\025", cbor.encode(cbor.decode("\024\025")))
	end);

	it("GGQ=", function()
		assert.are.same(100, cbor.decode("\024d"))
	end);

	it("GGQ=", function()
		assert.are.equal("\024d", cbor.encode(cbor.decode("\024d")))
	end);

	it("GQPo", function()
		assert.are.same(1000, cbor.decode("\025\003\232"))
	end);

	it("GQPo", function()
		assert.are.equal("\025\003\232", cbor.encode(cbor.decode("\025\003\232")))
	end);

	it("GgAPQkA=", function()
		assert.are.same(1000000, cbor.decode("\026\000\015B@"))
	end);

	it("GgAPQkA=", function()
		assert.are.equal("\026\000\015B@", cbor.encode(cbor.decode("\026\000\015B@")))
	end);

	it("GwAAAOjUpRAA", function()
		assert.are.same(1000000000000, cbor.decode("\027\000\000\000\232\212\165\016\000"))
	end);

	it("GwAAAOjUpRAA", function()
		assert.are.equal("\027\000\000\000\232\212\165\016\000", cbor.encode(cbor.decode("\027\000\000\000\232\212\165\016\000")))
	end);

	it("G///////////", function()
		assert.are.same(18446744073709551615, cbor.decode("\027\255\255\255\255\255\255\255\255"))
	end);

	--[[
	it("bignum", function()
		assert.are.same(18446744073709551616, cbor.decode("\194I\001\000\000\000\000\000\000\000\000"))
	end);
	--]]

--[[ Could not build test for O///////////
./myserialize.lua:233: bad argument #2 to 's_format' (not a number in proper range)
--]]

--[[ Could not build test for w0kBAAAAAAAAAAA=
./myserialize.lua:233: bad argument #2 to 's_format' (not a number in proper range)
--]]

	it("IA==", function()
		assert.are.same(-1, cbor.decode(" "))
	end);

	it("IA==", function()
		assert.are.equal(" ", cbor.encode(cbor.decode(" ")))
	end);

	it("KQ==", function()
		assert.are.same(-10, cbor.decode(")"))
	end);

	it("KQ==", function()
		assert.are.equal(")", cbor.encode(cbor.decode(")")))
	end);

	it("OGM=", function()
		assert.are.same(-100, cbor.decode("8c"))
	end);

	it("OGM=", function()
		assert.are.equal("8c", cbor.encode(cbor.decode("8c")))
	end);

	it("OQPn", function()
		assert.are.same(-1000, cbor.decode("9\003\231"))
	end);

	it("OQPn", function()
		assert.are.equal("9\003\231", cbor.encode(cbor.decode("9\003\231")))
	end);

	it("+QAA", function()
		assert.are.same(0, cbor.decode("\249\000\000"))
	end);

	it("+YAA", function()
		assert.are.same(0, cbor.decode("\249\128\000"))
	end);

	it("+TwA", function()
		assert.are.same(1, cbor.decode("\249<\000"))
	end);

	it("+z/xmZmZmZma", function()
		assert.are.same(1.1000000000, cbor.decode("\251?\241\153\153\153\153\153\154"))
	end);

	it("+z/xmZmZmZma", function()
		assert.are.equal("\251?\241\153\153\153\153\153\154", cbor.encode(cbor.decode("\251?\241\153\153\153\153\153\154")))
	end);

	it("+T4A", function()
		assert.are.same(1.5000000000, cbor.decode("\249>\000"))
	end);

	it("+Xv/", function()
		assert.are.same(65504, cbor.decode("\249{\255"))
	end);

	it("+kfDUAA=", function()
		assert.are.same(100000, cbor.decode("\250G\195P\000"))
	end);

	it("+n9///8=", function()
		assert.are.same(3.4028234663852886e+38, cbor.decode("\250\127\127\255\255"))
	end);

	it("+3435DyIAHWc", function()
		assert.are.same(1.0e+300, cbor.decode("\251~7\228<\136\000u\156"))
	end);

	it("+3435DyIAHWc", function()
		assert.are.equal("\251~7\228<\136\000u\156", cbor.encode(cbor.decode("\251~7\228<\136\000u\156")))
	end);

	it("+QAB", function()
		assert.are.same(5.960464477539063e-08, cbor.decode("\249\000\001"))
	end);

	it("+QQA", function()
		assert.are.same(6.103515625e-05, cbor.decode("\249\004\000"))
	end);

	it("+cQA", function()
		assert.are.same(-4.0, cbor.decode("\249\196\000"))
	end);

	it("+8AQZmZmZmZm", function ()
		assert.are.same(-4.1, cbor.decode("\251\192\016ffffff"))
	end);

	it("Infinity", function()
		assert.are.same(math.huge, cbor.decode("\249|\000"))
	end);

	it("NaN", function()
		assert.has_no.errors(function ()
			cbor.decode("\249~\000");
		end);
	end);

	it("-Infinity", function()
		assert.has_no.errors(function ()
			cbor.decode("\249\252\000");
		end);
	end);

	it("Infinity", function()
		assert.are.same(math.huge, cbor.decode("\250\127\128\000\000"));
	end);

	it("NaN", function()
		assert.has_no.errors(function ()
			cbor.decode("\250\127\192\000\000");
		end);
	end);

	it("-Infinity", function()
		assert.are.same(-math.huge, cbor.decode("\250\255\128\000\000"));
	end);

	it("Infinity", function()
		assert.are.same(math.huge, cbor.decode("\251\127\240\000\000\000\000\000\000"));
	end);

	it("NaN", function()
		assert.has_no.errors(function ()
			cbor.decode("\251\127\248\000\000\000\000\000\000");
		end);
	end);

	it("-Infinity", function()
		assert.are.same(-math.huge, cbor.decode("\251\255\240\000\000\000\000\000\000"));
	end);

	it("9A==", function()
		assert.are.same(false, cbor.decode("\244"))
	end);

	it("9A==", function()
		assert.are.equal("\244", cbor.encode(cbor.decode("\244")))
	end);

	it("9Q==", function()
		assert.are.same(true, cbor.decode("\245"))
	end);

	it("9Q==", function()
		assert.are.equal("\245", cbor.encode(cbor.decode("\245")))
	end);

	it("9g==", function()
		assert.are.equal(cbor.null, cbor.decode("\246"))
	end);

	it("9g==", function()
		assert.are.equal("\246", cbor.encode(cbor.decode("\246")))
	end);

	it("undefined", function()
		assert.are.equal(cbor.undefined, cbor.decode("\247"))
	end);

	it("simple(16)", function()
		assert.has_no.errors(function ()
			cbor.decode("\240");
		end);
	end);

	it("simple(24)", function()
		assert.has_no.errors(function ()
			cbor.decode("\248\024");
		end);
	end);

	it("simple(255)", function()
		assert.has_no.errors(function ()
			cbor.decode("\248\255");
		end);
	end);

	it("0(\"2013-03-21T20:04:00Z\")", function()
		assert.has_no.errors(function ()
			cbor.decode("\192t2013-03-21T20:04:00Z");
		end);
	end);

	it("1(1363896240)", function()
		assert.has_no.errors(function ()
			cbor.decode("\193\026QKg\176");
		end);
	end);

	it("1(1363896240.5)", function()
		assert.has_no.errors(function ()
			cbor.decode("\193\251A\212R\217\236 \000\000");
		end);
	end);

	it("23(h'01020304')", function()
		assert.has_no.errors(function ()
			cbor.decode("\215D\001\002\003\004");
		end);
	end);

	it("24(h'6449455446')", function()
		assert.has_no.errors(function ()
			cbor.decode("\216\024EdIETF");
		end);
	end);

	it("32(\"http://www.example.com\")", function()
		assert.has_no.errors(function ()
			cbor.decode("\216 vhttp://www.example.com");
		end);
	end);

	it("h''", function()
		assert.has_no.errors(function ()
			cbor.decode("@");
		end);
	end);

	it("h'01020304'", function()
		assert.has_no.errors(function ()
			cbor.decode("D\001\002\003\004");
		end);
	end);

	it("YA==", function()
		assert.are.same("", cbor.decode("`"))
	end);

	it("YWE=", function()
		assert.are.same("a", cbor.decode("aa"))
	end);

	it("ZElFVEY=", function()
		assert.are.same("IETF", cbor.decode("dIETF"))
	end);

	it("YiJc", function()
		assert.are.same("\"\\", cbor.decode("b\"\\"))
	end);

	it("YsO8", function()
		assert.are.same("\195\188", cbor.decode("b\195\188"))
	end);

	it("Y+awtA==", function()
		assert.are.same("\230\176\180", cbor.decode("c\230\176\180"))
	end);

	it("ZPCQhZE=", function()
		assert.are.same("\240\144\133\145", cbor.decode("d\240\144\133\145"))
	end);

	it("gA==", function()
		assert.are.same({}, cbor.decode("\128"))
	end);

	it("gA==", function()
		assert.are.equal("\128", cbor.encode(cbor.decode("\128")))
	end);

	it("gwECAw==", function()
		assert.are.same({1;2;3}, cbor.decode("\131\001\002\003"))
	end);

	it("gwECAw==", function()
		assert.are.equal("\131\001\002\003", cbor.encode(cbor.decode("\131\001\002\003")))
	end);

	it("gwGCAgOCBAU=", function()
		assert.are.same({1;{2;3};{4;5}}, cbor.decode("\131\001\130\002\003\130\004\005"))
	end);

	it("gwGCAgOCBAU=", function()
		assert.are.equal("\131\001\130\002\003\130\004\005", cbor.encode(cbor.decode("\131\001\130\002\003\130\004\005")))
	end);

	it("mBkBAgMEBQYHCAkKCwwNDg8QERITFBUWFxgYGBk=", function()
		assert.are.same({1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25}, cbor.decode("\152\025\001\002\003\004\005\006\a\b\t\n\v\f\r\014\015\016\017\018\019\020\021\022\023\024\024\024\025"))
	end);

	it("mBkBAgMEBQYHCAkKCwwNDg8QERITFBUWFxgYGBk=", function()
		assert.are.equal("\152\025\001\002\003\004\005\006\a\b\t\n\v\f\r\014\015\016\017\018\019\020\021\022\023\024\024\024\025", cbor.encode(cbor.decode("\152\025\001\002\003\004\005\006\a\b\t\n\v\f\r\014\015\016\017\018\019\020\021\022\023\024\024\024\025")))
	end);

	it("oA==", function()
		assert.are.same({}, cbor.decode("\160"))
	end);

	it("{1: 2, 3: 4}", function()
		assert.has_no.errors(function ()
			cbor.decode("\162\001\002\003\004");
		end);
	end);

	it("omFhAWFiggID", function()
		assert.are.same({b={2;3};a=1}, cbor.decode("\162aa\001ab\130\002\003"))
	end);

	it("gmFhoWFiYWM=", function()
		assert.are.same({"a";{b="c"}}, cbor.decode("\130aa\161abac"))
	end);

	it("pWFhYUFhYmFCYWNhQ2FkYURhZWFF", function()
		assert.are.same({b="B";a="A";d="D";c="C";e="E"}, cbor.decode("\165aaaAabaBacaCadaDaeaE"))
	end);

	it("(_ h'0102', h'030405')", function()
		assert.has_no.errors(function ()
			cbor.decode("_B\001\002C\003\004\005\255");
		end);
	end);

	it("f2VzdHJlYWRtaW5n/w==", function()
		assert.are.same("streaming", cbor.decode("\127estreadming\255"))
	end);

	it("n/8=", function()
		assert.are.same({}, cbor.decode("\159\255"))
	end);

	it("nwGCAgOfBAX//w==", function()
		assert.are.same({1;{2;3};{4;5}}, cbor.decode("\159\001\130\002\003\159\004\005\255\255"))
	end);

	it("nwGCAgOCBAX/", function()
		assert.are.same({1;{2;3};{4;5}}, cbor.decode("\159\001\130\002\003\130\004\005\255"))
	end);

	it("gwGCAgOfBAX/", function()
		assert.are.same({1;{2;3};{4;5}}, cbor.decode("\131\001\130\002\003\159\004\005\255"))
	end);

	it("gwGfAgP/ggQF", function()
		assert.are.same({1;{2;3};{4;5}}, cbor.decode("\131\001\159\002\003\255\130\004\005"))
	end);

	it("nwECAwQFBgcICQoLDA0ODxAREhMUFRYXGBgYGf8=", function()
		assert.are.same({1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25}, cbor.decode("\159\001\002\003\004\005\006\a\b\t\n\v\f\r\014\015\016\017\018\019\020\021\022\023\024\024\024\025\255"))
	end);

	it("v2FhAWFinwID//8=", function()
		assert.are.same({b={2;3};a=1}, cbor.decode("\191aa\001ab\159\002\003\255\255"))
	end);

	it("gmFhv2FiYWP/", function()
		assert.are.same({"a";{b="c"}}, cbor.decode("\130aa\191abac\255"))
	end);

	it("v2NGdW71Y0FtdCH/", function()
		assert.are.same({Fun=true;Amt=-2}, cbor.decode("\191cFun\245cAmt!\255"))
	end);

	it("long string", function ()
		local str = string.rep("nödåtgärd", 100);
		assert.are.equal(str, cbor.decode(cbor.encode(str)));
	end);

end);
