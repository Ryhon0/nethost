module coreclr_delegates;

// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

extern (C):

alias char_t = char;

enum UNMANAGEDCALLERSONLY_METHOD = cast(const(char_t)*) -1;

// Signature of delegate returned by coreclr_delegate_type::load_assembly_and_get_function_pointer
/* Fully qualified path to assembly */
/* Assembly qualified type name */
/* Public static method name compatible with delegateType */
/* Assembly qualified delegate type name or null
   or UNMANAGEDCALLERSONLY_METHOD if the method is marked with
   the UnmanagedCallersOnlyAttribute. */
/* Extensibility parameter (currently unused and must be 0) */
/*out*/ /* Pointer where to store the function pointer result */
alias load_assembly_and_get_function_pointer_fn = int function (
    const(char_t)* assembly_path,
    const(char_t)* type_name,
    const(char_t)* method_name,
    const(char_t)* delegate_type_name,
    void* reserved,
    void** delegate_);

// Signature of delegate returned by load_assembly_and_get_function_pointer_fn when delegate_type_name == null (default)
alias component_entry_point_fn = int function (void* arg, int arg_size_in_bytes);

/* Assembly qualified type name */
/* Public static method name compatible with delegateType */
/* Assembly qualified delegate type name or null,
   or UNMANAGEDCALLERSONLY_METHOD if the method is marked with
   the UnmanagedCallersOnlyAttribute. */
/* Extensibility parameter (currently unused and must be 0) */
/* Extensibility parameter (currently unused and must be 0) */
/*out*/ /* Pointer where to store the function pointer result */
alias get_function_pointer_fn = int function (
    const(char_t)* type_name,
    const(char_t)* method_name,
    const(char_t)* delegate_type_name,
    void* load_context,
    void* reserved,
    void** delegate_);

// __CORECLR_DELEGATES_H__
