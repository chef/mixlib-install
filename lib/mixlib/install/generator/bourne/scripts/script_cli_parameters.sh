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
############

# Defaults
channel="stable"
project="chef"

while getopts pnv:c:f:P:d:s:l:a opt
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
    \?)   # unknown flag
      echo >&2 \
      "usage: $0 [-P project] [-c release_channel] [-v version] [-f filename | -d download_dir] [-s install_strategy] [-l download_url_override] [-a checksum]"
      exit 1;;
  esac
done

shift `expr $OPTIND - 1`
