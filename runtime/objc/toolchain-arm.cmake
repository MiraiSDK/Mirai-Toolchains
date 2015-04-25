
SET(CMAKE_SYSTEM_NAME Linux)  # Tell CMake we're cross-compiling
SET(CMAKE_SYSTEM_PROCESSOR arm)

SET(CMAKE_C_COMPILER arm-linux-androideabi-clang)
SET(CMAKE_CXX_COMPILER arm-linux-androideabi-clang++)

SET(ANDROID TRUE)

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

