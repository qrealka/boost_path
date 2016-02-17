# Handle MSVC linker flags
if(MSVC)
  add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
  add_definitions(-DBOOST_ALL_NO_LIB)
  add_definitions(-DBOOST_ALL_DYN_LINK)
  add_definitions(-DUNICODE -D_UNICODE -U_MBCS -UMBCS)
  remove_definitions(-D_MBCS -DMBCS -DSBCS -D_SBCS)
else()
  # Handle libc++
  if(HAVE_LIBC++)
    set(LibCXX "-stdlib=libc++")
  endif()
  if(HAVE_LIBC++ABI)
    set(LibCXXAbi "-lc++abi")
  endif()
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "^(Apple)?Clang$")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LibCXX} ${LibCXXAbi} -lpthread -ldl")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  # Workaround for GCC bug https://bugs.launchpad.net/ubuntu/+source/gcc-defaults/+bug/1228201
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--no-as-needed -pthread")
endif()

