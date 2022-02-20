// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

extern (C):

alias char_t = char;

enum hostfxr_delegate_type
{
    hdt_com_activation = 0,
    hdt_load_in_memory_assembly = 1,
    hdt_winrt_activation = 2,
    hdt_com_register = 3,
    hdt_com_unregister = 4,
    hdt_load_assembly_and_get_function_pointer = 5,
    hdt_get_function_pointer = 6
}

alias hostfxr_main_fn = int function (const int argc, const(char_t*)* argv);
alias hostfxr_main_startupinfo_fn = int function (
    const int argc,
    const(char_t*)* argv,
    const(char_t)* host_path,
    const(char_t)* dotnet_root,
    const(char_t)* app_path);
alias hostfxr_main_bundle_startupinfo_fn = int function (
    const int argc,
    const(char_t*)* argv,
    const(char_t)* host_path,
    const(char_t)* dotnet_root,
    const(char_t)* app_path,
    long bundle_header_offset);

alias hostfxr_error_writer_fn = void function (const(char_t)* message);

//
// Sets a callback which is to be used to write errors to.
//
// Parameters:
//     error_writer
//         A callback function which will be invoked every time an error is to be reported.
//         Or nullptr to unregister previously registered callback and return to the default behavior.
// Return value:
//     The previously registered callback (which is now unregistered), or nullptr if no previous callback
//     was registered
//
// The error writer is registered per-thread, so the registration is thread-local. On each thread
// only one callback can be registered. Subsequent registrations overwrite the previous ones.
//
// By default no callback is registered in which case the errors are written to stderr.
//
// Each call to the error writer is sort of like writing a single line (the EOL character is omitted).
// Multiple calls to the error writer may occure for one failure.
//
// If the hostfxr invokes functions in hostpolicy as part of its operation, the error writer
// will be propagated to hostpolicy for the duration of the call. This means that errors from
// both hostfxr and hostpolicy will be reporter through the same error writer.
//
alias hostfxr_set_error_writer_fn = void function (hostfxr_error_writer_fn error_writer) function (hostfxr_error_writer_fn error_writer);

alias hostfxr_handle = void*;

struct hostfxr_initialize_parameters
{
    size_t size;
    const(char_t)* host_path;
    const(char_t)* dotnet_root;
}

//
// Initializes the hosting components for a dotnet command line running an application
//
// Parameters:
//    argc
//      Number of argv arguments
//    argv
//      Command-line arguments for running an application (as if through the dotnet executable).
//      Only command-line arguments which are accepted by runtime installation are supported, SDK/CLI commands are not supported.
//      For example 'app.dll app_argument_1 app_argument_2`.
//    parameters
//      Optional. Additional parameters for initialization
//    host_context_handle
//      On success, this will be populated with an opaque value representing the initialized host context
//
// Return value:
//    Success          - Hosting components were successfully initialized
//    HostInvalidState - Hosting components are already initialized
//
// This function parses the specified command-line arguments to determine the application to run. It will
// then find the corresponding .runtimeconfig.json and .deps.json with which to resolve frameworks and
// dependencies and prepare everything needed to load the runtime.
//
// This function only supports arguments for running an application. It does not support SDK commands.
//
// This function does not load the runtime.
//

/*out*/
alias hostfxr_initialize_for_dotnet_command_line_fn = int function (
    int argc,
    const(char_t*)* argv,
    const(hostfxr_initialize_parameters)* parameters,
    hostfxr_handle* host_context_handle);

//
// Initializes the hosting components using a .runtimeconfig.json file
//
// Parameters:
//    runtime_config_path
//      Path to the .runtimeconfig.json file
//    parameters
//      Optional. Additional parameters for initialization
//    host_context_handle
//      On success, this will be populated with an opaque value representing the initialized host context
//
// Return value:
//    Success                            - Hosting components were successfully initialized
//    Success_HostAlreadyInitialized     - Config is compatible with already initialized hosting components
//    Success_DifferentRuntimeProperties - Config has runtime properties that differ from already initialized hosting components
//    CoreHostIncompatibleConfig         - Config is incompatible with already initialized hosting components
//
// This function will process the .runtimeconfig.json to resolve frameworks and prepare everything needed
// to load the runtime. It will only process the .deps.json from frameworks (not any app/component that
// may be next to the .runtimeconfig.json).
//
// This function does not load the runtime.
//
// If called when the runtime has already been loaded, this function will check if the specified runtime
// config is compatible with the existing runtime.
//
// Both Success_HostAlreadyInitialized and Success_DifferentRuntimeProperties codes are considered successful
// initializations. In the case of Success_DifferentRuntimeProperties, it is left to the consumer to verify that
// the difference in properties is acceptable.
//

/*out*/
alias hostfxr_initialize_for_runtime_config_fn = int function (
    const(char_t)* runtime_config_path,
    const(hostfxr_initialize_parameters)* parameters,
    hostfxr_handle* host_context_handle);

//
// Gets the runtime property value for an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//     name
//       Runtime property name
//     value
//       Out parameter. Pointer to a buffer with the property value.
//
// Return value:
//     The error code result.
//
// The buffer pointed to by value is owned by the host context. The lifetime of the buffer is only
// guaranteed until any of the below occur:
//   - a 'run' method is called for the host context
//   - properties are changed via hostfxr_set_runtime_property_value
//   - the host context is closed via 'hostfxr_close'
//
// If host_context_handle is nullptr and an active host context exists, this function will get the
// property value for the active host context.
//

/*out*/
alias hostfxr_get_runtime_property_value_fn = int function (
    const hostfxr_handle host_context_handle,
    const(char_t)* name,
    const(char_t*)* value);

//
// Sets the value of a runtime property for an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//     name
//       Runtime property name
//     value
//       Value to set
//
// Return value:
//     The error code result.
//
// Setting properties is only supported for the first host context, before the runtime has been loaded.
//
// If the property already exists in the host context, it will be overwritten. If value is nullptr, the
// property will be removed.
//
alias hostfxr_set_runtime_property_value_fn = int function (
    const hostfxr_handle host_context_handle,
    const(char_t)* name,
    const(char_t)* value);

//
// Gets all the runtime properties for an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//     count
//       [in] Size of the keys and values buffers
//       [out] Number of properties returned (size of keys/values buffers used). If the input value is too
//             small or keys/values is nullptr, this is populated with the number of available properties
//     keys
//       Array of pointers to buffers with runtime property keys
//     values
//       Array of pointers to buffers with runtime property values
//
// Return value:
//     The error code result.
//
// The buffers pointed to by keys and values are owned by the host context. The lifetime of the buffers is only
// guaranteed until any of the below occur:
//   - a 'run' method is called for the host context
//   - properties are changed via hostfxr_set_runtime_property_value
//   - the host context is closed via 'hostfxr_close'
//
// If host_context_handle is nullptr and an active host context exists, this function will get the
// properties for the active host context.
//

/*inout*/
/*out*/
/*out*/
alias hostfxr_get_runtime_properties_fn = int function (
    const hostfxr_handle host_context_handle,
    size_t* count,
    const(char_t*)* keys,
    const(char_t*)* values);

//
// Load CoreCLR and run the application for an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//
// Return value:
//     If the app was successfully run, the exit code of the application. Otherwise, the error code result.
//
// The host_context_handle must have been initialized using hostfxr_initialize_for_dotnet_command_line.
//
// This function will not return until the managed application exits.
//
alias hostfxr_run_app_fn = int function (const hostfxr_handle host_context_handle);

//
// Gets a typed delegate from the currently loaded CoreCLR or from a newly created one.
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//     type
//       Type of runtime delegate requested
//     delegate
//       An out parameter that will be assigned the delegate.
//
// Return value:
//     The error code result.
//
// If the host_context_handle was initialized using hostfxr_initialize_for_runtime_config,
// then all delegate types are supported.
// If the host_context_handle was initialized using hostfxr_initialize_for_dotnet_command_line,
// then only the following delegate types are currently supported:
//     hdt_load_assembly_and_get_function_pointer
//     hdt_get_function_pointer
//

/*out*/
alias hostfxr_get_runtime_delegate_fn = int function (
    const hostfxr_handle host_context_handle,
    hostfxr_delegate_type type,
    void** delegate_);

//
// Closes an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//
// Return value:
//     The error code result.
//
alias hostfxr_close_fn = int function (const hostfxr_handle host_context_handle);

struct hostfxr_dotnet_environment_sdk_info
{
    size_t size;
    const(char_t)* version_;
    const(char_t)* path;
}

alias hostfxr_get_dotnet_environment_info_result_fn = void function (
    const(hostfxr_dotnet_environment_info)* info,
    void* result_context);

struct hostfxr_dotnet_environment_framework_info
{
    size_t size;
    const(char_t)* name;
    const(char_t)* version_;
    const(char_t)* path;
}

struct hostfxr_dotnet_environment_info
{
    size_t size;

    const(char_t)* hostfxr_version;
    const(char_t)* hostfxr_commit_hash;

    size_t sdk_count;
    const(hostfxr_dotnet_environment_sdk_info)* sdks;

    size_t framework_count;
    const(hostfxr_dotnet_environment_framework_info)* frameworks;
}

//__HOSTFXR_H__
