cmake_minimum_required(VERSION 3.16)
project(pokecrystal C CXX)

include(CheckIPOSupported)
include(FetchContent)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()
if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        add_compile_options(-O0 -g)
    else()
        add_compile_options(-O3)
    endif()
endif()

# ---------------------------------------------------------------------------
# gb-recompiled runtime
# When consumed by an umbrella compilation (e.g. GB-Recomp/pgbcomp), the
# parent is expected to provide `gbrt`. We detect that and skip the fetch.
# ---------------------------------------------------------------------------
if(NOT TARGET gbrt)
    set(GBRT_REF "main" CACHE STRING "git ref of GB-Recomp/gb-recompiled to use")
    FetchContent_Declare(gb_recompiled
        GIT_REPOSITORY https://github.com/GB-Recomp/gb-recompiled.git
        GIT_TAG ${GBRT_REF}
        GIT_SHALLOW TRUE
    )
    FetchContent_GetProperties(gb_recompiled)
    if(NOT gb_recompiled_POPULATED)
        FetchContent_Populate(gb_recompiled)
    endif()
    add_subdirectory(${gb_recompiled_SOURCE_DIR}/runtime ${CMAKE_BINARY_DIR}/_gbrt_build)
endif()

# ---------------------------------------------------------------------------
# Cart sources
# ---------------------------------------------------------------------------
set(POKECRYSTAL_SOURCES
    pokecrystal_main.c
    pokecrystal.c
    pokecrystal_rom.c
    pokecrystal_dispatch_chunk_0.c
    pokecrystal_dispatch_chunk_1.c
    pokecrystal_dispatch_chunk_2.c
    pokecrystal_dispatch_chunk_3.c
    pokecrystal_dispatch_chunk_4.c
    pokecrystal_funcs_0.c
    pokecrystal_funcs_1.c
    pokecrystal_funcs_2.c
    pokecrystal_funcs_3.c
    pokecrystal_funcs_4.c
    pokecrystal_funcs_5.c
    pokecrystal_funcs_6.c
    pokecrystal_funcs_7.c
    pokecrystal_funcs_8.c
    pokecrystal_funcs_9.c
    pokecrystal_funcs_10.c
    pokecrystal_funcs_11.c
    pokecrystal_funcs_12.c
    pokecrystal_funcs_13.c
    pokecrystal_funcs_14.c
    pokecrystal_funcs_15.c
    pokecrystal_funcs_16.c
    pokecrystal_funcs_17.c
    pokecrystal_funcs_18.c
    pokecrystal_funcs_19.c
    pokecrystal_funcs_20.c
    pokecrystal_funcs_21.c
    pokecrystal_funcs_22.c
    pokecrystal_funcs_23.c
    pokecrystal_funcs_24.c
    pokecrystal_funcs_25.c
    pokecrystal_funcs_26.c
    pokecrystal_funcs_27.c
    pokecrystal_funcs_28.c
    pokecrystal_funcs_29.c
    pokecrystal_funcs_30.c
    pokecrystal_funcs_31.c
    pokecrystal_funcs_32.c
    pokecrystal_funcs_33.c
    pokecrystal_funcs_34.c
    pokecrystal_funcs_35.c
    pokecrystal_funcs_36.c
    pokecrystal_funcs_37.c
    pokecrystal_funcs_38.c
    pokecrystal_funcs_39.c
    pokecrystal_funcs_40.c
    pokecrystal_funcs_41.c
    pokecrystal_funcs_42.c
    pokecrystal_funcs_43.c
    pokecrystal_funcs_44.c
    pokecrystal_funcs_45.c
    pokecrystal_funcs_46.c
    pokecrystal_funcs_47.c
    pokecrystal_funcs_48.c
    pokecrystal_funcs_49.c
    pokecrystal_funcs_50.c
    pokecrystal_funcs_51.c
    pokecrystal_funcs_52.c
    pokecrystal_funcs_53.c
    pokecrystal_funcs_54.c
    pokecrystal_funcs_55.c
    pokecrystal_funcs_56.c
    pokecrystal_funcs_57.c
    pokecrystal_funcs_58.c
    pokecrystal_funcs_59.c
    pokecrystal_funcs_60.c
    pokecrystal_funcs_61.c
)

set(GBRECOMP_GENERATED_OPT_LEVEL "3" CACHE STRING "Optimization level for generated ROM source files")
set_property(CACHE GBRECOMP_GENERATED_OPT_LEVEL PROPERTY STRINGS 0 1 2 3)
set_source_files_properties(${POKECRYSTAL_SOURCES} PROPERTIES COMPILE_OPTIONS "-O${GBRECOMP_GENERATED_OPT_LEVEL}")

# ---------------------------------------------------------------------------
# pokecrystal_cart: static library so umbrella compilations can link us in.
# Exposes `pokecrystal_main(argc, argv)` for the launcher's g_games[].
# ---------------------------------------------------------------------------
add_library(pokecrystal_cart STATIC ${POKECRYSTAL_SOURCES})
target_include_directories(pokecrystal_cart PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(pokecrystal_cart PUBLIC gbrt)

# ---------------------------------------------------------------------------
# Standalone launcher executable. Only built when this is the top-level
# CMake project.
# ---------------------------------------------------------------------------
if(CMAKE_PROJECT_NAME STREQUAL "pokecrystal")
    add_executable(pokecrystal_launcher launcher_main.cpp)
    target_link_libraries(pokecrystal_launcher PRIVATE pokecrystal_cart gbrt)
    set_target_properties(pokecrystal_launcher PROPERTIES OUTPUT_NAME pokecrystal)
endif()
