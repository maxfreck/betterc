/**
 * Betterc: Frequently used primitives suitable for use in the BetterC D subset.
 * inspired by https://theartofmachinery.com/2018/05/27/cpp_classes_in_betterc.html
 *
 * Copyright: Maxim Freck, 2018.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module betterc.cppclass;

import std.traits: ReturnType;

/*******
 * Returns `true` if `T` is destructible with `T.destructor()` method.
 * In other words tests whether `T` contains `void destructor()` method.
 * Please note: the parent destructor must be called explicitly.
 */
enum bool isDestructable(T) = is(ReturnType!((T r) => r.destructor) == void);

/*******
 * Creates an instance of T inside the malloc'd memory and calls its constructor.
 *
 * Params:
 *  Args... = Constructor arguments
 *
 * Returns: an instance of a class of type T
 */
T cnew(T, Args...)(auto ref Args args)
{
	import core.stdc.stdlib: malloc;
	import core.stdc.string: memcpy;

	static immutable model = new T();
	enum kTSize = __traits(classInstanceSize, T);
	auto instance = cast(T)malloc(kTSize);
	memcpy(cast(void*)instance, cast(void*)model, kTSize);
	instance.__ctor(args);

	return instance;
}

/*******
 * Calls the destructor of a previously malloc'd class and frees its memory
 *
 * `__xdtor()` is non-virtual and non-@nogc
 * so let's just use destructor() method
 * before freing object's memory
 *
 * Params:
 *  instance = Class instance
 */
void cdelete(T)(T instance)
{
	import core.stdc.stdlib: free;

	static if(isDestructable!T) instance.destructor();
	free(cast(void*)instance);
}

