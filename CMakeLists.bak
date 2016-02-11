cmake_minimum_required(VERSION 3.4)

include("cmake/HunterGate.cmake")
set(HUNTER_STATUS_DEBUG ON)
set(HUNTER_PACKAGE_LOG_BUILD ON)
#set(HUNTER_RUN_INSTALL ON)

HunterGate(
        URL "https://github.com/ruslo/hunter/archive/v0.10.9.tar.gz"
        SHA1 "53b198e364dc7bc8360fc545f798563229bd7e20"
)

project(boost_path)

# download boost
hunter_add_package(Boost COMPONENTS system locale filesystem)

# now boost can be used
set(Boost_USE_STATIC_LIBS OFF)
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_RUNTIME OFF)
find_package(Boost CONFIG REQUIRED system locale filesystem)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
set(SOURCE_FILES main.cpp)

if(Boost_FOUND)
    include_directories(${Boost_INCLUDE_DIRS})
    add_executable(boost_path ${SOURCE_FILES})
    target_link_libraries(boost_path PUBLIC Boost::system Boost::locale Boost::filesystem)
endif()