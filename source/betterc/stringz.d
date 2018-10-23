/**
 * Betterc: Frequently used primitives suitable for use in the BetterC D subset.
 *
 * Copyright: Maxim Freck, 2018.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module betterc.stringz;

/*******
 * Reference-counted null-terminated string
 */
struct Stringz
{
	private struct Payload {
		char* dst;
		size_t length;

		size_t count;
		@disable this(this); // not copyable
	}

	private Payload *payload;

	/*******
	* Constructor
	*
	* Params:
	*  src = the D-style string
	*/
	public this(string src) nothrow @nogc
	{
		import core.stdc.stdlib: malloc;
		import core.stdc.string: memcpy;

		payload = (cast(Payload*)malloc(Payload.sizeof));

		payload.count = 1;
		payload.length = src.length;
		payload.dst = cast(char*)malloc(src.length+1);
		memcpy(payload.dst, src.ptr, src.length);
		payload.dst[src.length] = 0;

	}

	this (this) nothrow @nogc
	{
		payload.count++;
	}

	///Ref. counting during structure assignment
	ref typeof(this) opAssign()(auto ref typeof(this) rhs) nothrow @nogc
	{
		this.payload = rhs.payload;
		payload.count++;
		return this;
	}

	~this() nothrow @nogc
	{
		import core.stdc.stdlib: free;
		if (--payload.count == 0) {
			free(payload.dst);
			free(payload);
		}
	}

	pragma(inline)
	T opCast(T:immutable(char)*)() pure nothrow @nogc
	{
		return *this;
	}

	immutable(char)* opUnary(string s)() nothrow @nogc if (s == "*")
	{
		return cast(immutable(char)*)payload.dst;
	}

	immutable(size_t) length() nothrow @nogc
	{
		return payload.length;
	}
}