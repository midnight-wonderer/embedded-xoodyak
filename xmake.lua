-- xmake.lua

package("unity")
    set_homepage("https://github.com/ThrowTheSwitch/Unity")
    set_description("Simple Unit Testing for C")
    set_urls("https://github.com/ThrowTheSwitch/Unity.git")

    on_install(function (package)
        io.writefile("xmake.lua", [[
            target("unity")
                set_kind("$(kind)")
                add_files("src/unity.c")
                add_includedirs("src", {public = true})
                add_headerfiles("src/unity.h", "src/unity_internals.h")
        ]])
        import("package.tools.xmake").install(package)
    end)
package_end()

add_rules("mode.debug", "mode.release")

add_requires("unity master")

target("xoodyak")
    set_kind("static")
    add_files("src/Xoodyak.c")
    add_files("src/Xoodoo-portable.c")
    add_files("src/Xoodoo-helpers.c")
    add_files("src/Xoodoo-lx106.S")
    add_files("src/Xoodoo-armv6m.S")
    add_files("src/Xoodoo-armv7m.S")
    add_includedirs("include")
    set_languages("c99")

target("test_embedded_xoodyak")
    set_kind("binary")
    add_files("test_embedded_xoodyak.c")
    add_includedirs("include")
    add_deps("xoodyak")
    add_packages("unity")
    set_languages("c99")
