#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------

# Inner script to run inside Docker containers to build the 
# GNU MCU Eclipse ARM Embedded GCC distribution packages.

# For native builds, it runs on the host (macOS build cases,
# and development builds for GNU/Linux).

# -----------------------------------------------------------------------------

# ----- Identify helper scripts. -----

build_script_path=$0
if [[ "${build_script_path}" != /* ]]
then
  # Make relative path absolute.
  build_script_path=$(pwd)/$0
fi

script_folder_path="$(dirname ${build_script_path})"
script_folder_name="$(basename ${script_folder_path})"

defines_script_path="${script_folder_path}/defs-source.sh"
echo "Definitions source script: \"${defines_script_path}\"."
source "${defines_script_path}"

TARGET_OS=""
TARGET_BITS=""
HOST_UNAME=""

# This file is generated by the host build script.
host_defines_script_path="${script_folder_path}/host-defs-source.sh"
echo "Host definitions source script: \"${host_defines_script_path}\"."
source "${host_defines_script_path}"

container_lib_functions_script_path="${script_folder_path}/${CONTAINER_LIB_FUNCTIONS_SCRIPT_NAME}"
echo "Container lib functions source script: \"${container_lib_functions_script_path}\"."
source "${container_lib_functions_script_path}"

container_functions_script_path="${script_folder_path}/helper/container-functions-source.sh"
echo "Container functions source script: \"${container_functions_script_path}\"."
source "${container_functions_script_path}"

# -----------------------------------------------------------------------------

WITHOUT_STRIP=""
MULTILIB_FLAGS="" # by default multilib is enabled
WITHOUT_PDF=""
IS_DEVELOP=""

while [ $# -gt 0 ]
do

  case "$1" in

    --disable-strip)
      WITHOUT_STRIP="y"
      shift
      ;;

    --without-pdf)
      WITHOUT_PDF="y"
      shift
      ;;

    --disable-multilib)
      MULTILIB_FLAGS="--disable-multilib"
      shift
      ;;

    --jobs)
      JOBS="--jobs=$2"
      shift 2
      ;;

    --develop)
      IS_DEVELOP="y"
      shift
      ;;

    *)
      echo "Unknown action/option $1"
      exit 1
      ;;

  esac

done

# -----------------------------------------------------------------------------

container_start_timer

container_detect

container_prepare_prerequisites

# -----------------------------------------------------------------------------

# Make all tools choose gcc, not the old cc.
export CC=gcc
export CXX=g++

EXTRA_CFLAGS="-ffunction-sections -fdata-sections -m${TARGET_BITS} -pipe"
EXTRA_CXXFLAGS="-ffunction-sections -fdata-sections -m${TARGET_BITS} -pipe"
EXTRA_CPPFLAGS="-I${INSTALL_FOLDER_PATH}/include"
EXTRA_LDFLAGS_LIB="-L${INSTALL_FOLDER_PATH}/lib"
EXTRA_LDFLAGS="${EXTRA_LDFLAGS_LIB} -static-libstdc++"

export PKG_CONFIG=pkg-config-verbose
export PKG_CONFIG_LIBDIR="${INSTALL_FOLDER_PATH}/lib/pkgconfig"

# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------

do_gmp
do_mpfr
do_mpc
do_isl

do_expat
do_libiconv
do_xz

# -----------------------------------------------------------------------------

container_stop_timer

exit 0

# -----------------------------------------------------------------------------
