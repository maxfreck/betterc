/**
 * Betterc: Frequently used primitives suitable for use in the BetterC D subset.
 *
 * Copyright: Maxim Freck, 2018.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module betterc.file;

/*******
 * Encapsulates a $(D FILE*).
 */
struct File {
	private import core.stdc.stdio;//: SEEK_SET, SEEK_CUR, SEEK_END, FILE;
	private import core.stdc.stdlib: malloc, free;
	private import betterc.stringz: Stringz;

	/// Offset is relative to the beginning
	enum seekSet = SEEK_SET;
	/// Offset is relative to the current position
	enum seekCur = SEEK_CUR;
	/// Offset is relative to the end
	enum seekEnd = SEEK_END;


	private struct Payload {
		Stringz filename;
		FILE *fd;

		size_t count;
		@disable this(this); // not copyable
	}

	private Payload *payload;

	/*******
	* Creates a temporary file without a name
	*/
	public static typeof(this) tmpfile() nothrow @nogc
	{
		return File(core.stdc.stdio.tmpfile());
	}

	private this(FILE *f) nothrow @nogc
	{
		payload = (cast(Payload*)malloc(Payload.sizeof));
		payload.filename = Stringz("");
		payload.fd = f;
		payload.count = 1;
	}

	/*******
	* Constructor
	*
	* Params:
	*  filename = Null terminated file name
	*  mode = Null terminated access mode
	*/
	public this(string filename, in string mode) nothrow @nogc
	{
		payload = (cast(Payload*)malloc(Payload.sizeof));
		payload.filename = Stringz(filename);
		payload.fd = fopen(*payload.filename, *Stringz(mode));
		payload.count = 1;
	}

	///ditto
	this (this) nothrow @nogc
	{
		if (payload !is null)
			payload.count++;
	}

	///Ref. counting during structure assignment
	ref typeof(this) opAssign(ref typeof(this) rhs)
	{
		this.payload = rhs.payload;
		if (payload !is null)
			payload.count++;

		return this;
	}

	/*******
	* Destructor: frees all memory
	*/
	~this() nothrow @nogc
	{
		if (payload !is null && --payload.count == 0) {
			this.close();
			free(payload);
		}
	}


	/*******
	* Reuses stream to change its access mode.
	*
	* Params:
	*  mode = Null terminated access mode
	*/
	public void reopen(in string mode) nothrow @nogc
	{
		payload.fd = freopen(*payload.filename, *Stringz(mode), payload.fd);
	}

	/*******
	* Returns: underlying FILE*
	*/
	public FILE* stream() nothrow @nogc
	{
		return payload.fd;
	}

	///ditto
	pragma(inline)
	FILE* opUnary(string s)() nothrow @nogc if (s == "*")
	{
		return payload.fd;
	}

	/*******
	* Reads up to count objects into the array buffer
	*
	* Params:
	*  ptr   = pointer to the first object in the array to be read
	*  size  = size of each object in bytes
	*  nmemb = the number of the objects to be read
	*
	* Returns: number of objects read successfully
	*/
	public size_t read(void* ptr, size_t size, size_t nmemb) nothrow @nogc
	{
		return fread(ptr, size, nmemb, payload.fd);
	}

	///ditto
	public size_t read(T)(T[] buf) nothrow @nogc
	{
		return read(buf.ptr, T.sizeof, buf.length);
	}


	/*******
	* Writes up to count binary objects from the given array buffer
	*
	* Params:
	*  ptr   = pointer to the first object object in the array to be written
	*  size  = size of each object in bytes
	*  nmemb = the number of the objects to be read
	*
	* Returns: number of objects written successfully
	*/
	public size_t write(in void* ptr, size_t size, size_t nmemb) nothrow @nogc
	{
		return fwrite(ptr, size, nmemb, payload.fd);
	}

	///ditto
	public size_t write(T)(in T[] buf) nothrow @nogc
	{
		return write(buf.ptr, T.sizeof, buf.length);
	}



	ref typeof(this) opBinary(char* op, T)(in T[] pos) if (op == "<<")
	{
		write(buf.ptr, T.sizeof, buf.length);
		return this;
	}

	//---
	public size_t read(T)(ref T b) nothrow @nogc
	{
		return read(&b, T.sizeof, 1);
	}

	public size_t write(T)(in T b) nothrow @nogc
	{
		return write(&b, T.sizeof, 1);
	}

	ref typeof(this) opBinary(char* op, T)(in T b) if (op == "<<")
	{
		write(&b, T.sizeof, 1);
		return this;
	}

	ref typeof(this) opBinary(char* op)(string str) if (op == "<<")
	{
		write(str.ptr, 1, str.length);
		return this;
	}

	/+++ It's broken at the moment
	extern(C) public int dprintf(string format, ...) nothrow @nogc
	{
		va_list args;
		va_start(args, format);
		return vfprintf(payload.fd, *Stringz(format), args);
	}

	extern(C) public int printf(in char* format, ...) nothrow @nogc
	{
		va_list args;
		va_start(args, format);
		return vfprintf(payload.fd, format, args);
	}
	+++/

	/*******
	* Returns: the length of the FILE*
	*/
	public size_t length() nothrow @nogc
	{
		immutable auto seekSave = ftell(payload.fd);
		fseek(payload.fd, 0, SEEK_END);
		auto fileSize = ftell(payload.fd);
		fseek(payload.fd, seekSave, SEEK_SET);
		return fileSize;
	}

	/*******
	* Returns: true if the end of the stream has been reached, otherwise false
	*/
	public bool eof() nothrow @nogc
	{
		return feof(payload.fd) > 0;
	}

	/*******
	* Sets the file position indicator
	*
	* Params:
	*  offset = number of characters to shift the position relative to origin
	*  origin = position to which offset is added
	*
	* Returns: true upon success, false otherwise
	*/
	public bool seek(size_t offset, int origin) nothrow @nogc
	{
		return fseek(payload.fd, cast(int)offset, origin) == 0;
	}

	/*******
	* Checks the stream for errors
	*
	* Returns: true if the file stream has errors occurred, ​false​ otherwise
	*/
	public bool error() nothrow @nogc
	{
		return ferror(payload.fd) > 0;
	}

	/*******
	* Writes any unwritten data from the stream's buffer to the associated output device
	*
	* Returns: true on success
	*/
	public bool flush() nothrow @nogc
	{
		return fflush(payload.fd) == 0;
	}

	/*******
	* Closes the file stream
	*
	* Returns: true on success
	*/
	public void close() nothrow @nogc
	{
		if (payload.fd == null) return;

		fclose(payload.fd);
		payload.fd = null;
	}
}
