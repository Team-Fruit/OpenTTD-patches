function(configure_lto)
    if(OPTION_NO_LTO)
        return()
    endif()

    set_ipo()

    if(NOT LTO_FOUND AND WIN32 AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
        # VS maps CMake's IPO property to WholeProgramOptimization; ClangCL does
        # not reliably translate that into Full LTO. Specify it on every TU.
        foreach(target IN LISTS targets)
            # below is now in CompileFlags.cmake
            target_compile_options(${target} PRIVATE
                "$<$<OR:$<CONFIG:Release>,$<CONFIG:MinSizeRel>,$<CONFIG:RelWithDebInfo>>:-flto=full>")
        endforeach()
        # LLD identifies LLVM bitcode inputs; do not pass Clang
        # driver flags to lld-link itself.
    endif()
endfunction()

function(set_ipo)
    if(OPTION_NO_LTO)
        return()
    endif()

    set(targets ${OPENTTD_LIB} openttd)
    if(TARGET openttd_test)
        list(APPEND targets openttd_test)
    endif()
    list(REMOVE_DUPLICATES targets)

    # LTO_FOUND variable is from compile_flags() macro defined in CompileFlags.cmake, and it is used to determine whether use '-flto' or not.
    # if LTO_FOUND evaluated as true, LTO flags are already inserted and should not turn on INTERPROCEDURAL_OPTIMIZATION
    # otherwise, '-flto' flag is not supported by current compiler or compile_flags() macro is not used before this function
    if(LTO_FOUND OR (WIN32 AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC"))
        foreach(target IN LISTS targets)
            set_target_properties(${target} PROPERTIES
                    INTERPROCEDURAL_OPTIMIZATION_RELEASE FALSE
                    INTERPROCEDURAL_OPTIMIZATION_MINSIZEREL FALSE
                    INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO FALSE)
        endforeach ()
    elseif(IPO_FOUND)
        foreach(target IN LISTS targets)
            set_target_properties(${target} PROPERTIES
                INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
                INTERPROCEDURAL_OPTIMIZATION_MINSIZEREL TRUE
                INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO TRUE)
        endforeach ()
    endif()
endfunction()