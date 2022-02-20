module app;

import std.conv;
import std.stdio;
import std.string;
import std.exception;
import std.file : thisExePath;

import nethost;
import hostfxr;
import coreclr_delegates;

hostfxr_initialize_for_runtime_config_fn init_fptr;
hostfxr_get_runtime_delegate_fn get_delegate_fptr;
hostfxr_close_fn close_fptr;

void main()
{
	// STEP 1: Load HostFxr and get exported hosting functions
	enforce(loadHostFXR(), "Failed to load hostfxr");

	string libname = "DotNetLib";
	string fw = "net6.0";

	// STEP 2: Initialize and start the .NET Core runtime
	string configpath = libname ~ "/bin/Debug/" ~ fw ~ "/" ~ libname ~ ".runtimeconfig.json";
	load_assembly_and_get_function_pointer_fn load_assembly_and_get_function_pointer = null;
	load_assembly_and_get_function_pointer = getDotnetLoadAssembly(configpath.toStringz);
	assert(load_assembly_and_get_function_pointer, "Failure: get_dotnet_load_assembly()");

	// STEP 3: Load managed assembly and get function pointer to a managed method
	component_entry_point_fn hello = null;
	string dotnetlibpath = libname ~ "/bin/Debug/" ~ fw ~ "/" ~ libname ~ ".dll";
	string dotnettype = "DotNetLib.Lib, DotNetLib";
	string dotnettypemethod = "Hello";
	int rc = load_assembly_and_get_function_pointer(
		dotnetlibpath.toStringz,
		dotnettype.toStringz,
		dotnettypemethod.toStringz,
		null,
		null,
		cast(void**)&hello);
	assert(rc == 0 && hello, "Failure: load_assembly_and_get_function_pointer()");

	struct lib_args
	{
		const char_t* message;
		int number;
	}

	for (int i = 0; i < 3; ++i)
	{
		lib_args args = {"Hello from D", i};
		hello(&args, args.sizeof);
	}

	// TODO:
	/*
	#ifdef NET5_0
	// Function pointer to managed delegate with non-default signature
	typedef void (CORECLR_DELEGATE_CALLTYPE *custom_entry_point_fn)(lib_args args);
	custom_entry_point_fn custom = nullptr;
	rc = load_assembly_and_get_function_pointer(
		dotnetlib_path.c_str(),
		dotnet_type,
		STR("CustomEntryPointUnmanaged"),
		UNMANAGEDCALLERSONLY_METHOD,
		nullptr,
		(void**)&custom);
	assert(rc == 0 && custom != nullptr && "Failure: load_assembly_and_get_function_pointer()");
#else
	// Function pointer to managed delegate with non-default signature
	typedef void (CORECLR_DELEGATE_CALLTYPE *custom_entry_point_fn)(lib_args args);
	custom_entry_point_fn custom = nullptr;
	rc = load_assembly_and_get_function_pointer(
		dotnetlib_path.c_str(),
		dotnet_type,
		STR("CustomEntryPoint"),
		STR("DotNetLib.Lib+CustomEntryPointDelegate, DotNetLib"),
		nullptr,
		(void**)&custom);
	assert(rc == 0 && custom != nullptr && "Failure: load_assembly_and_get_function_pointer()");
#endif

	lib_args args
	{
		STR("from host!"),
		-1
	};
	custom(args);
	*/
}

hostfxr_initialize_parameters runtime_params;
// Using the nethost library, discover the location of hostfxr and get exports
bool loadHostFXR()
{
	// Pre-allocate a large buffer for the path to hostfxr
	char_t[1024] bf;
	size_t bfsize = bf.sizeof / char_t.sizeof;

	// For whatever reason, this is needed, unlike in the C++ example
	// Without it, it'll compain about no runtimes being found
	string libpath = "/usr/share/dotnet";
	immutable char_t* exec_path = thisExePath().toStringz;
	runtime_params = hostfxr_initialize_parameters(hostfxr_initialize_parameters.sizeof, exec_path, "/usr/share/dotnet");

	int rc = get_hostfxr_path(cast(char*) bf, &bfsize, null);
	if (rc)
		return false;

	// Load hostfxr and get desired exports
	void* lib = load_library(cast(char*) bf);
	init_fptr = cast(hostfxr_initialize_for_runtime_config_fn) get_export(lib, "hostfxr_initialize_for_runtime_config");
	get_delegate_fptr = cast(hostfxr_get_runtime_delegate_fn) get_export(lib, "hostfxr_get_runtime_delegate");
	close_fptr = cast(hostfxr_close_fn) get_export(lib, "hostfxr_close");

	return init_fptr && get_delegate_fptr && close_fptr;
}

// Load and initialize .NET Core and get desired function pointer for scenario
load_assembly_and_get_function_pointer_fn getDotnetLoadAssembly(const char_t* config_path)
{
	// Load .NET Core
	void* load_assembly_and_get_function_pointer = null;
	hostfxr_handle ctx = null;
	int rc = init_fptr(config_path, &runtime_params, &ctx);
	if (rc || ctx is null)
	{
		stderr.writeln("Init failed: " ~ rc.to!string);
		close_fptr(ctx);
		return null;
	}

	// Get the load assembly function pointer
	rc = get_delegate_fptr(
		ctx,
		hostfxr_delegate_type.hdt_load_assembly_and_get_function_pointer,
		&load_assembly_and_get_function_pointer);

	if (rc || load_assembly_and_get_function_pointer)
		stderr.writeln("Get delegate failed: " ~ rc.to!string);

	close_fptr(ctx);
	return cast(load_assembly_and_get_function_pointer_fn) load_assembly_and_get_function_pointer;
}

void* load_library(const char_t* path)
{
	version (Posix)
	{
		import core.sys.posix.dlfcn;

		void* h = dlopen(path, RTLD_LAZY | RTLD_LOCAL);
		assert(h);
		return h;
	}
	else version (Windows)
	{
		import core.sys.windows.windows;

		void* h = LoadLibraryW(path);
		assert(h);
		return h;
	}
}

void* get_export(void* h, const char_t* path)
{
	version (Posix)
	{
		import core.sys.posix.dlfcn;

		void* f = dlsym(h, path);
		assert(f);
		return f;
	}
	else version (Windows)
	{
		import core.sys.windows.windows;

		void* f = GetProcAddress(h, path);
		assert(f);
		return f;
	}
}
