#!/bin/sh
# WARNING: REQUIRES /bin/sh
#
# - must run on /bin/sh on solaris 9
# - must run on /bin/sh on AIX 6.x
#
# Copyright:: Copyright (c) 2010-2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# helpers.sh
############
# This section has some helper functions to make life easier.
#
# Outputs:
# $tmp_dir: secure-ish temp directory that can be used during installation.
############

# Check whether a command exists - returns 0 if it does, 1 if it does not
exists() {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}

# Output the instructions to report bug about this script
report_bug() {
  echo "Version: $version"
  echo ""
  echo "Please file a Bug Report at https://github.com/chef/omnitruck/issues/new"
  echo "Alternatively, feel free to open a Support Ticket at https://www.chef.io/support/tickets"
  echo "More Chef support resources can be found at https://www.chef.io/support"
  echo ""
  echo "Please include as many details about the problem as possible i.e., how to reproduce"
  echo "the problem (if possible), type of the Operating System and its version, etc.,"
  echo "and any other relevant details that might help us with troubleshooting."
  echo ""
}

checksum_mismatch() {
  echo "Package checksum mismatch!"
  report_bug
  exit 1
}

unable_to_retrieve_package() {
  echo "Unable to retrieve a valid package!"
  report_bug
  echo "Metadata URL: $metadata_url"
  if test "x$download_url" != "x"; then
    echo "Download URL: $download_url"
  fi
  if test "x$stderr_results" != "x"; then
    echo "\nDEBUG OUTPUT FOLLOWS:\n$stderr_results"
  fi
  exit 1
}

http_404_error() {
  echo "Omnitruck artifact does not exist for version $version on platform $platform"
  echo ""
  echo "Either this means:"
  echo "   - We do not support $platform"
  echo "   - We do not have an artifact for $version"
  echo ""
  echo "This is often the latter case due to running a prerelease or RC version of Chef"
  echo "or a gem version which was only pushed to rubygems and not omnitruck."
  echo ""
  echo "You may be able to set your knife[:bootstrap_version] to the most recent stable"
  echo "release of Chef to fix this problem (or the most recent stable major version number)."
  echo ""
  echo "In order to test the version parameter, adventurous users may take the Metadata URL"
  echo "below and modify the '&v=<number>' parameter until you successfully get a URL that"
  echo "does not 404 (e.g. via curl or wget).  You should be able to use '&v=11' or '&v=12'"
  echo "successfully."
  echo ""
  echo "If you cannot fix this problem by setting the bootstrap_version, it probably means"
  echo "that $platform is not supported."
  echo ""
  # deliberately do not call report_bug to suppress bug report noise.
  echo "Metadata URL: $metadata_url"
  if test "x$download_url" != "x"; then
    echo "Download URL: $download_url"
  fi
  if test "x$stderr_results" != "x"; then
    echo "\nDEBUG OUTPUT FOLLOWS:\n$stderr_results"
  fi
  exit 1
}

capture_tmp_stderr() {
  # spool up /tmp/stderr from all the commands we called
  if test -f "$tmp_dir/stderr"; then
    output=`cat $tmp_dir/stderr`
    stderr_results="${stderr_results}\nSTDERR from $1:\n\n$output\n"
    rm $tmp_dir/stderr
  fi
}

# do_wget URL FILENAME
do_wget() {
  echo "trying wget..."
  # If filename is empty, use --content-disposition to get filename from server
  if test "x$2" = "x"; then
    wget --user-agent="User-Agent: mixlib-install/3.13.1" --content-disposition "$1" 2>$tmp_dir/stderr
  else
    wget --user-agent="User-Agent: mixlib-install/3.13.1" -O "$2" "$1" 2>$tmp_dir/stderr
  fi
  rc=$?
  # check for 404
  grep "ERROR 404" $tmp_dir/stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    echo "ERROR 404"
    http_404_error
  fi

  # check for bad return status (skip empty output check if using content-disposition)
  if test $rc -ne 0; then
    capture_tmp_stderr "wget"
    return 1
  fi
  
  # Only check for empty output if we specified a filename
  if test "x$2" != "x" && test ! -s "$2"; then
    capture_tmp_stderr "wget"
    return 1
  fi

  return 0
}

# do_curl URL FILENAME
do_curl() {
  echo "trying curl..."
  # If filename is empty, use -O and -J to get filename from Content-Disposition header
  if test "x$2" = "x"; then
    curl -A "User-Agent: mixlib-install/3.13.1" --retry 5 -sL -D $tmp_dir/stderr -O -J "$1"
    rc=$?
  else
    curl -A "User-Agent: mixlib-install/3.13.1" --retry 5 -sL -D $tmp_dir/stderr "$1" > "$2"
    rc=$?
  fi
  
  # check for 404
  grep "404 Not Found" $tmp_dir/stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    echo "ERROR 404"
    http_404_error
  fi

  # check for bad return status
  if test $rc -ne 0; then
    capture_tmp_stderr "curl"
    return 1
  fi
  
  # Only check for empty output if we specified a filename
  if test "x$2" != "x" && test ! -s "$2"; then
    capture_tmp_stderr "curl"
    return 1
  fi

  return 0
}

# do_fetch URL FILENAME
do_fetch() {
  echo "trying fetch..."
  fetch --user-agent="User-Agent: mixlib-install/3.13.1" -o "$2" "$1" 2>$tmp_dir/stderr
  # check for bad return status
  test $? -ne 0 && return 1
  return 0
}

# do_perl URL FILENAME
do_perl() {
  echo "trying perl..."
  perl -e 'use LWP::Simple; getprint($ARGV[0]);' "$1" > "$2" 2>$tmp_dir/stderr
  rc=$?
  # check for 404
  grep "404 Not Found" $tmp_dir/stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    echo "ERROR 404"
    http_404_error
  fi

  # check for bad return status or empty output
  if test $rc -ne 0 || test ! -s "$2"; then
    capture_tmp_stderr "perl"
    return 1
  fi

  return 0
}

# do_python URL FILENAME
do_python() {
  echo "trying python..."
  python -c "import sys,urllib2; sys.stdout.write(urllib2.urlopen(urllib2.Request(sys.argv[1], headers={ 'User-Agent': 'mixlib-install/3.13.1' })).read())" "$1" > "$2" 2>$tmp_dir/stderr
  rc=$?
  # check for 404
  grep "HTTP Error 404" $tmp_dir/stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    echo "ERROR 404"
    http_404_error
  fi

  # check for bad return status or empty output
  if test $rc -ne 0 || test ! -s "$2"; then
    capture_tmp_stderr "python"
    return 1
  fi
  return 0
}

# returns 0 if checksums match
do_checksum() {
  if exists sha256sum; then
    echo "Comparing checksum with sha256sum..."
    checksum=`sha256sum $1 | awk '{ print $1 }'`
    return `test "x$checksum" = "x$2"`
  elif exists shasum; then
    echo "Comparing checksum with shasum..."
    checksum=`shasum -a 256 $1 | awk '{ print $1 }'`
    return `test "x$checksum" = "x$2"`
  else
    echo "WARNING: could not find a valid checksum program, pre-install shasum or sha256sum in your O/S image to get validation..."
    return 0
  fi
}

# do_download URL FILENAME
do_download() {
  echo "downloading $1"
  echo "  to file $2"

  url=`echo $1`
  if test "x$platform" = "xsolaris2"; then
    if test "x$platform_version" = "x5.9" -o "x$platform_version" = "x5.10"; then
      # solaris 9 lacks openssl, solaris 10 lacks recent enough credentials - your base O/S is completely insecure, please upgrade
      url=`echo $url | sed -e 's/https/http/'`
    fi
  fi

  # we try all of these until we get success.
  # perl, in particular may be present but LWP::Simple may not be installed

  if exists wget; then
    do_wget $url $2 && return 0
  fi

  if exists curl; then
    do_curl $url $2 && return 0
  fi

  if exists fetch; then
    do_fetch $url $2 && return 0
  fi

  if exists perl; then
    do_perl $url $2 && return 0
  fi

  if exists python; then
    do_python $url $2 && return 0
  fi

  unable_to_retrieve_package
}

# install_file TYPE FILENAME
# TYPE is "rpm", "deb", "solaris", "sh", etc.
install_file() {
  echo "Installing $project $version"
  case "$1" in
    "rpm")
      if test "x$platform" = "xnexus" || test "x$platform" = "xios_xr"; then
        echo "installing with yum..."
        yum install -yv "$2"
      else
        echo "installing with rpm..."
        rpm -Uvh --oldpackage --replacepkgs "$2"
      fi
      ;;
    "deb")
      echo "installing with dpkg..."
      dpkg -i "$2"
      ;;
    "bff")
      echo "installing with installp..."
      installp -aXYgd "$2" all
      ;;
    "solaris")
      echo "installing with pkgadd..."
      echo "conflict=nocheck" > $tmp_dir/nocheck
      echo "action=nocheck" >> $tmp_dir/nocheck
      echo "mail=" >> $tmp_dir/nocheck
      pkgrm -a $tmp_dir/nocheck -n $project >/dev/null 2>&1 || true
      pkgadd -G -n -d "$2" -a $tmp_dir/nocheck $project
      ;;
    "pkg")
      echo "installing with installer..."
      cd / && /usr/sbin/installer -pkg "$2" -target /
      ;;
    "dmg")
      echo "installing dmg file..."
      hdiutil detach "/Volumes/chef_software" >/dev/null 2>&1 || true
      hdiutil attach "$2" -mountpoint "/Volumes/chef_software"
      cd / && /usr/sbin/installer -pkg `find "/Volumes/chef_software" -name \*.pkg` -target /
      hdiutil detach "/Volumes/chef_software"
      ;;
    "sh" )
      echo "installing with sh..."
      sh "$2"
      ;;
    "p5p" )
      echo "installing p5p package..."
      pkg install -g "$2" $project
      ;;
    *)
      echo "Unknown filetype: $1"
      report_bug
      exit 1
      ;;
  esac
  if test $? -ne 0; then
    echo "Installation failed"
    report_bug
    exit 1
  fi
}

if test "x$TMPDIR" = "x"; then
  tmp="/tmp"
else
  tmp=$TMPDIR
fi
# secure-ish temp dir creation without having mktemp available (DDoS-able but not exploitable)
tmp_dir="$tmp/install.sh.$$"
(umask 077 && mkdir $tmp_dir) || exit 1

############
# end of helpers.sh
############


# script_cli_parameters.sh
############
# This section reads the CLI parameters for the install script and translates
#   them to the local parameters to be used later by the script.
#
# Outputs:
# $version: Requested version to be installed.
# $channel: Channel to install the product from
# $project: Project to be installed
# $cmdline_filename: Name of the package downloaded on local disk.
# $cmdline_dl_dir: Name of the directory downloaded package will be saved to on local disk.
# $install_strategy: Method of package installations. default strategy is to always install upon exec. Set to "once" to skip if project is installed
# $download_url_override: Install package downloaded from a direct URL.
# $checksum: SHA256 for download_url_override file (optional)
# $license_id: License ID for commercial API access (optional)
############

# Defaults
channel="stable"
project="chef"

while getopts pnv:c:f:P:d:s:l:a:L: opt
do
  case "$opt" in

    v)  version="$OPTARG";;
    c)  channel="$OPTARG";;
    p)  channel="current";; # compat for prerelease option
    n)  channel="current";; # compat for nightlies option
    f)  cmdline_filename="$OPTARG";;
    P)  project="$OPTARG";;
    d)  cmdline_dl_dir="$OPTARG";;
    s)  install_strategy="$OPTARG";;
    l)  download_url_override="$OPTARG";;
    a)  checksum="$OPTARG";;
    L)  license_id="$OPTARG";;
    \?)   # unknown flag
      echo >&2 \
      "usage: $0 [-P project] [-c release_channel] [-v version] [-f filename | -d download_dir] [-s install_strategy] [-l download_url_override] [-a checksum] [-L license_id]"
      exit 1;;
  esac
done

shift `expr $OPTIND - 1`


# Check for chef-client command in various locations
for path in /hab/pkgs/chef/chef-infra-client/*/*/bin/chef-client "/usr/bin/${project}-client" "/opt/$project/bin/${project}-client"; do
  if test -x "$path" 2>/dev/null && test "x$install_strategy" = "xonce"; then
    echo "$project installation detected at $path"
    echo "install_strategy set to 'once'"
    echo "Nothing to install"
    exit
  fi
done


# platform_detection.sh
############
# This section makes platform detection compatible with omnitruck on the system
#   it runs.
#
# Outputs:
# $platform: Name of the platform.
# $platform_version: Version of the platform.
# $machine: System's architecture.
############

#
# Platform and Platform Version detection
#
# NOTE: This logic should match ohai platform and platform_version matching.
# do not invent new platform and platform_version schemas, just make this behave
# like what ohai returns as platform and platform_version for the system.
#
# ALSO NOTE: Do not mangle platform or platform_version here.  It is less error
# prone and more future-proof to do that in the server, and then all omnitruck clients
# will 'inherit' the changes (install.sh is not the only client of the omnitruck
# endpoint out there).
#

machine=`uname -m`
os=`uname -s`

if test -f "/etc/lsb-release" && grep DISTRIB_ID /etc/lsb-release >/dev/null && ! grep wrlinux /etc/lsb-release >/dev/null; then
  platform=`grep DISTRIB_ID /etc/lsb-release | cut -d "=" -f 2 | tr '[A-Z]' '[a-z]'`
  platform_version=`grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f 2`

  if test "$platform" = "\"cumulus linux\""; then
    platform="cumulus_linux"
  elif test "$platform" = "\"cumulus networks\""; then
    platform="cumulus_networks"
  fi

elif test -f "/etc/debian_version"; then
  platform="debian"
  platform_version=`cat /etc/debian_version`
elif test -f "/etc/Eos-release"; then
  # EOS may also contain /etc/redhat-release so this check must come first.
  platform=arista_eos
  platform_version=`awk '{print $4}' /etc/Eos-release`
  machine="i386"
elif test -f "/etc/redhat-release"; then
  platform=`sed 's/^\(.\+\) release.*/\1/' /etc/redhat-release | tr '[A-Z]' '[a-z]'`
  platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release`
  
  if test "$platform" = "rocky linux"; then
  	source /etc/os-release
 	os="${REDHAT_SUPPORT_PRODUCT}"
  	platform_version="${ROCKY_SUPPORT_PRODUCT_VERSION}"
        platform=$ID

  elif test "$platform" = "xenserver"; then
    # Current XenServer 6.2 is based on CentOS 5, platform is not reset to "el" server should handle response
    platform="xenserver"
  else
    # FIXME: use "redhat"
    platform="el"
  fi

elif test -f "/etc/system-release"; then
  platform=`sed 's/^\(.\+\) release.\+/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
  platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
  case $platform in amazon*) # sh compat method of checking for a substring
    . /etc/os-release
    platform_version=$VERSION_ID

    case $platform_version in
      "2022"|"2023")
        platform="amazon"
        platform_version=$platform_version
      ;;
      "2")
        platform="el"
        platform_version="7"
        ;;
      *)
        platform="el"

        # VERSION_ID will match YYYY.MM for Amazon Linux AMIs
        platform_version="6"
        ;;
    esac
  esac


# Apple macOS
elif test -f "/usr/bin/sw_vers"; then
  platform="mac_os_x"
  # Matching the tab-space with sed is error-prone
  platform_version=`sw_vers | awk '/^ProductVersion:/ { print $2 }' | cut -d. -f1,2`
elif test -f "/etc/release"; then
  machine=`/usr/bin/uname -p`
  if grep SmartOS /etc/release >/dev/null; then
    platform="smartos"
    platform_version=`grep ^Image /etc/product | awk '{ print $3 }'`
  else
    platform="solaris2"
    platform_version=`/usr/bin/uname -r`
  fi
elif test -f "/etc/SuSE-release"; then
  if grep 'Enterprise' /etc/SuSE-release >/dev/null;
  then
      platform="sles"
      platform_version=`awk '/^VERSION/ {V = $3}; /^PATCHLEVEL/ {P = $3}; END {print V "." P}' /etc/SuSE-release`
  else # opensuse 43 only. 15 ships with /etc/os-release only
      platform="opensuseleap"
      platform_version=`awk '/^VERSION =/ { print $3 }' /etc/SuSE-release`
  fi
elif test "x$os" = "xFreeBSD"; then
  platform="freebsd"
  platform_version=`uname -r | sed 's/-.*//'`
elif test "x$os" = "xAIX"; then
  platform="aix"
  platform_version="`uname -v`.`uname -r`"
  machine="powerpc"
elif test -f "/etc/os-release"; then
  . /etc/os-release
  if test "x$CISCO_RELEASE_INFO" != "x"; then
    . $CISCO_RELEASE_INFO
  fi

  platform=$ID

  # VERSION_ID is always the preferred variable to use, but not
  # every distro has it so fallback to VERSION
  if test "x$VERSION_ID" != "x"; then
    platform_version=$VERSION_ID
  else
    platform_version=$VERSION
  fi
fi

if test "x$platform" = "x"; then
  echo "Unable to determine platform version!"
  report_bug
  exit 1
fi

#
# NOTE: platform mangling in the install.sh is DEPRECATED
#
# - install.sh should be true to ohai and should not remap
#   platform or platform versions.
#
# - remapping platform and mangling platform version numbers is
#   now the complete responsibility of the server-side endpoints
#

major_version=`echo $platform_version | cut -d. -f1`
case $platform in
  # FIXME: should remove this case statement completely
  "el")
    # FIXME:  "el" is deprecated, should use "redhat"
    platform_version=$major_version
    ;;
  "debian")
    if test "x$major_version" = "x5"; then
      # This is here for potential back-compat.
      # We do not have 5 in versions we publish for anymore but we
      # might have it for earlier versions.
      platform_version="6"
    else
      platform_version=$major_version
    fi
    ;;
  "freebsd")
    platform_version=$major_version
    ;;
  "sles")
    platform_version=$major_version
    ;;
  "opensuseleap")
    platform_version=$major_version
    ;;
esac

# normalize the architecture we detected
case $machine in
  "arm64"|"aarch64")
    machine="aarch64"
    ;;
  "x86_64"|"amd64"|"x64")
    machine="x86_64"
    ;;
  "i386"|"i86pc"|"x86"|"i686")
    machine="i386"
    ;;
  "sparc"|"sun4u"|"sun4v")
    machine="sparc"
    ;;
esac

if test "x$platform_version" = "x"; then
  echo "Unable to determine platform version!"
  report_bug
  exit 1
fi

if test "x$platform" = "xsolaris2"; then
  # hack up the path on Solaris to find wget, pkgadd
  PATH=/usr/sfw/bin:/usr/sbin:$PATH
  export PATH
fi

echo "$platform $platform_version $machine"

############
# end of platform_detection.sh
############


# All of the download utilities in this script load common proxy env vars.
# If variables are set they will override any existing env vars.
# Otherwise, default proxy env vars will be loaded by the respective
# download utility.

if test "x$https_proxy" != "x"; then
  echo "setting https_proxy: $https_proxy"
  HTTPS_PROXY=$https_proxy
  https_proxy=$https_proxy
  export HTTPS_PROXY
  export https_proxy
fi

if test "x$http_proxy" != "x"; then
  echo "setting http_proxy: $http_proxy"
  HTTP_PROXY=$http_proxy
  http_proxy=$http_proxy
  export HTTP_PROXY
  export http_proxy
fi

if test "x$ftp_proxy" != "x"; then
  echo "setting ftp_proxy: $ftp_proxy"
  FTP_PROXY=$ftp_proxy
  ftp_proxy=$ftp_proxy
  export FTP_PROXY
  export ftp_proxy
fi

if test "x$no_proxy" != "x"; then
  echo "setting no_proxy: $no_proxy"
  NO_PROXY=$no_proxy
  no_proxy=$no_proxy
  export NO_PROXY
  export no_proxy
fi


# fetch_metadata.sh
############
# This section calls omnitruck to get the information about the build to be
#   installed.
#
# Inputs:
# $channel:
# $project:
# $version:
# $platform:
# $platform_version:
# $machine:
# $tmp_dir:
#
# Outputs:
# $download_url:
# $sha256:
############

if test "x$download_url_override" = "x"; then
  echo "Getting information for $project $channel $version for $platform..."

  metadata_filename="$tmp_dir/metadata.txt"

  # Use commercial API if license_id is provided, otherwise use omnitruck
  if test "x$license_id" != "x"; then
    # Check if license_id starts with 'free-' or 'trial-' for trial API
    case "$license_id" in
      free-*|trial-*)
        # Trial API endpoint
        base_api_url="https://chefdownload-trial.chef.io"
        ;;
      *)
        # Commercial API endpoint
        base_api_url="https://chefdownload-commercial.chef.io"
        ;;
    esac
    metadata_url="$base_api_url/$channel/$project/metadata?v=$version&p=$platform&pv=$platform_version&m=$machine&license_id=$license_id"
  else
    # Omnitruck endpoint
    metadata_url="https://omnitruck.chef.io/$channel/$project/metadata?v=$version&p=$platform&pv=$platform_version&m=$machine"
  fi

  do_download "$metadata_url"  "$metadata_filename"

  cat "$metadata_filename"

  echo ""

  # Commercial and trial APIs return JSON, omnitruck returns text format
  if test "x$license_id" != "x"; then
    # Parse JSON response from commercial/trial API
    # Check if response looks like JSON
    if grep -q '^{' "$metadata_filename" 2>/dev/null; then
      # Extract url and sha256 from JSON
      # Try using sed for simple JSON parsing (more portable than jq)
      download_url=`sed -n 's/.*"url":"\([^"]*\)".*/\1/p' "$metadata_filename"`
      sha256=`sed -n 's/.*"sha256":"\([^"]*\)".*/\1/p' "$metadata_filename"`

      if test "x$download_url" != "x" && test "x$sha256" != "x"; then
        echo "downloaded metadata file looks valid..."
      else
        echo "downloaded metadata file is corrupted or an uncaught error was encountered in downloading the file..."
        report_bug
        exit 1
      fi
    else
      echo "downloaded metadata file is corrupted or an uncaught error was encountered in downloading the file..."
      report_bug
      exit 1
    fi
  else
    # Parse text response from omnitruck
    if grep '^url' $metadata_filename > /dev/null && grep '^sha256' $metadata_filename > /dev/null; then
      echo "downloaded metadata file looks valid..."
      download_url=`awk '$1 == "url" { print $2 }' "$metadata_filename"`
      sha256=`awk '$1 == "sha256" { print $2 }' "$metadata_filename"`
    else
      echo "downloaded metadata file is corrupted or an uncaught error was encountered in downloading the file..."
      # this generally means one of the download methods downloaded a 404 or something like that and then reported a successful exit code,
      # and this should be fixed in the function that was doing the download.
      report_bug
      exit 1
    fi
  fi
else
  download_url=$download_url_override
  # Set sha256 to empty string if checksum not set
  sha256=${checksum=""}
fi

############
# end of fetch_metadata.sh
############


# fetch_package.sh
############
# This section fetches a package from $download_url and verifies its metadata.
#
# Inputs:
# $download_url:
# $tmp_dir:
# Optional Inputs:
# $cmdline_filename: Name of the package downloaded on local disk.
# $cmdline_dl_dir: Name of the directory downloaded package will be saved to on local disk.
# $license_id: If set, indicates we're using commercial/trial API with content-disposition headers
#
# Outputs:
# $download_filename: Name of the downloaded file on local disk.
# $filetype: Type of the file downloaded.
############

# For licensed APIs (commercial/trial), the URL is an endpoint, not a direct file URL
# The actual filename will come from the Content-Disposition header
if test "x$license_id" != "x"; then
  # Use content-disposition to get the filename
  use_content_disposition="true"
  # We don't know the filename yet - it will come from Content-Disposition
  # Just set the download directory
  if test "x$cmdline_filename" != "x"; then
    download_filename="$cmdline_filename"
    download_dir=`dirname $download_filename`
    use_content_disposition="false"  # User specified exact filename
  elif test "x$cmdline_dl_dir" != "x"; then
    download_dir="$cmdline_dl_dir"
    download_filename=""  # Will be determined after download
  else
    download_dir="$tmp_dir"
    download_filename=""  # Will be determined after download
  fi
  filetype=""  # Will be determined after we get the actual filename
else
  # Traditional omnitruck URLs have the filename in the URL
  use_content_disposition="false"
  filename=`echo $download_url | sed -e 's/?.*//' | sed -e 's/^.*\///'`
  filetype=`echo $filename | sed -e 's/^.*\.//'`

  # use either $tmp_dir, the provided directory (-d) or the provided filename (-f)
  if test "x$cmdline_filename" != "x"; then
    download_filename="$cmdline_filename"
  elif test "x$cmdline_dl_dir" != "x"; then
    download_filename="$cmdline_dl_dir/$filename"
  else
    download_filename="$tmp_dir/$filename"
  fi
  download_dir=`dirname $download_filename`
fi
(umask 077 && mkdir -p $download_dir) || exit 1

# check if we have that file locally available and if so verify the checksum
# Use cases
# 1) metadata - new download
# 2) metadata - cached download when cmdline_dl_dir set
# 3) url override - no checksum new download
# 4) url override - with checksum new download
# 5) url override - with checksum cached download when cmdline_dl_dir set

cached_file_available="false"
verify_checksum="true"

# Skip caching checks when using content-disposition since we don't know the real filename yet
if test "x$use_content_disposition" = "xtrue"; then
  cached_file_available="false"
  verify_checksum="true"
elif test "x$download_filename" != "x" && test -f "$download_filename"; then
  echo "$download_filename exists"
  cached_file_available="true"
fi

if test "x$download_url_override" != "x" && test "x$use_content_disposition" = "xfalse"; then
  echo "Download URL override specified"
  if test "x$cached_file_available" = "xtrue"; then
    echo "Verifying local file"
    if test "x$sha256" = "x"; then
      echo "Checksum not specified, ignoring existing file"
      cached_file_available="false" # download new file
      verify_checksum="false" # no checksum to compare after download
    elif do_checksum "$download_filename" "$sha256"; then
      echo "Checksum match, using existing file"
      cached_file_available="true" # don't need to download file
      verify_checksum="false" # don't need to checksum again
    else
      echo "Checksum mismatch, ignoring existing file"
      cached_file_available="false" # download new file
      verify_checksum="true" # checksum new downloaded file
    fi
  else
    echo "$download_filename not found"
    cached_file_available="false" # download new file
    if test "x$sha256" = "x"; then
      verify_checksum="false" # no checksum to compare after download
    else
      verify_checksum="true" # checksum new downloaded file
    fi
  fi
fi

if test "x$cached_file_available" != "xtrue"; then
  if test "x$use_content_disposition" = "xtrue"; then
    # For licensed APIs, download to a temporary file and extract filename from response headers
    # The download_dir was already set during initialization above

    # Create temp file for download
    temp_download="$download_dir/chef-download-temp.$$"

    # Download to temp file
    do_download "$download_url" "$temp_download"

    # Extract filename from response headers (try multiple methods for compatibility)
    if test -f "$tmp_dir/stderr"; then
      # Method 1: Try to extract filename from content-disposition header
      # Format: content-disposition: attachment; filename="chef-18.8.54-1.el9.x86_64.rpm"
      actual_filename=`grep -i 'content-disposition' $tmp_dir/stderr | sed -n 's/.*filename="\([^"]*\)".*/\1/p' | head -1`

      # Method 2: If content-disposition failed, try to extract from location redirect header
      # Format: location: https://packages.chef.io/files/stable/chef/18.8.54/el/9/chef-18.8.54-1.el9.x86_64.rpm?licenseId=...
      if test "x$actual_filename" = "x"; then
        actual_filename=`grep -i '^location:' $tmp_dir/stderr | head -1 | sed 's/.*\///' | sed 's/?.*//'`
      fi

      # Method 3: Try extracting from any URL-like pattern in stderr
      if test "x$actual_filename" = "x"; then
        actual_filename=`grep -i '\.rpm\|\.deb\|\.pkg\|\.msi\|\.dmg' $tmp_dir/stderr | sed -n 's/.*\/\([^/?]*\.\(rpm\|deb\|pkg\|msi\|dmg\)\).*/\1/p' | head -1`
      fi
    fi

    # If we still couldn't extract from headers, construct filename from metadata
    if test "x$actual_filename" = "x"; then
      echo "Warning: Could not extract filename from response headers, using fallback"
      # Construct a reasonable filename from available metadata
      # This is a fallback and may not match the exact package name
      if test "x$platform" = "xel" || test "x$platform" = "xfedora" || test "x$platform" = "xamazon"; then
        actual_filename="chef-${version}-1.${platform}${platform_version}.${machine}.rpm"
      elif test "x$platform" = "xdebian" || test "x$platform" = "xubuntu"; then
        actual_filename="chef_${version}-1_${machine}.deb"
      elif test "x$platform" = "xmac_os_x"; then
        actual_filename="chef-${version}.dmg"
      else
        actual_filename="chef-${version}.pkg"
      fi
    fi

    download_filename="$download_dir/$actual_filename"

    # Move temp file to final location
    mv "$temp_download" "$download_filename"

    # Extract filetype from actual filename
    filetype=`echo $actual_filename | sed -e 's/^.*\.//'`

    echo "Downloaded as: $download_filename (type: $filetype)"
  else
    # Traditional download with known filename
    do_download "$download_url" "$download_filename"
  fi
fi

if test "x$verify_checksum" = "xtrue"; then
  do_checksum "$download_filename" "$sha256" || checksum_mismatch
fi

############
# end of fetch_package.sh
############


# install_package.sh
############
# Installs a package and removed the temp directory.
#
# Inputs:
# $download_filename: Name of the file to be installed.
# $filetype: Type of the file to be installed.
# $version: The version requested. Used only for warning user if not set.
############

if test "x$version" = "x" -a "x$CI" != "xtrue"; then
  echo
  echo "WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING"
  echo
  echo "You are installing a package without a version pin.  If you are installing"
  echo "on production servers via an automated process this is DANGEROUS and you will"
  echo "be upgraded without warning on new releases, even to new major releases."
  echo "Letting the version float is only appropriate in test, development or"
  echo "CI/CD environments."
  echo
  echo "WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING"
  echo
fi

install_file $filetype "$download_filename"

if test "x$tmp_dir" != "x"; then
  rm -r "$tmp_dir"
fi

############
# end of install_package.sh
############
