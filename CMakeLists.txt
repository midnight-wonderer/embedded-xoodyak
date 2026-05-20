cmake_minimum_required(VERSION 3.13)

if(COMMAND idf_component_register)
    # ESP-IDF build system integration
    idf_component_register(
        SRCS
            "src/Xoodyak.c"
            "src/Xoodoo-portable.c"
            "src/Xoodoo-helpers.c"
            "src/Xoodoo-lx106.S"
            "src/Xoodoo-armv6m.S"
            "src/Xoodoo-armv7m.S"
        INCLUDE_DIRS
            "include"
    )
    message(STATUS "embedded-xoodyak: Registered as an ESP-IDF component.")

else()
    # Standard CMake build system integration
    project(embedded-xoodyak LANGUAGES C)

    # Check if ASM (assembly) language is supported/configured by the toolchain
    enable_language(ASM OPTIONAL)

    # Core C source files
    set(SOURCES
        src/Xoodyak.c
        src/Xoodoo-portable.c
        src/Xoodoo-helpers.c
    )

    # Add optimized assembly implementations if ASM is available
    if(CMAKE_ASM_COMPILER_LOADED)
        list(APPEND SOURCES
            src/Xoodoo-lx106.S
            src/Xoodoo-armv6m.S
            src/Xoodoo-armv7m.S
        )
        message(STATUS "ASM compiler loaded. Including target-specific assembly optimizations.")
    else()
        message(STATUS "ASM compiler not loaded. Compiling with portable C fallback only.")
    endif()

    # Define the static library target
    add_library(xoodyak STATIC ${SOURCES})

    # Configure include directories
    target_include_directories(xoodyak PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    )

    # Set standard properties
    set_target_properties(xoodyak PROPERTIES
        C_STANDARD 99
        C_STANDARD_REQUIRED ON
    )

    # Support installation (useful for system package managers and packaging)
    include(GNUInstallDirs)

    install(TARGETS xoodyak
        EXPORT embedded-xoodyak-targets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )

    install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

    install(EXPORT embedded-xoodyak-targets
        FILE embedded-xoodyak-config.cmake
        NAMESPACE embedded-xoodyak::
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/embedded-xoodyak
    )
endif()
