# fetch_package.sh
############
# This section fetchs a package from $download_url and verifies its metadata.
#
# Inputs:
# $download_url:
# $tmp_dir:
# Optional Inputs:
# $cmdline_filename: Name of the package downloaded on local disk.
# $cmdline_dl_dir: Name of the directory downloaded package will be saved to on local disk.
#
# Outputs:
# $download_filename: Name of the downloaded file on local disk.
# $filetype: Type of the file downloaded.
############

filename=`echo $download_url | sed -e 's/^.*\///'`
filetype=`echo $filename | sed -e 's/^.*\.//'`

# use either $tmp_dir, the provided directory (-d) or the provided filename (-f)
if test "x$cmdline_filename" != "x"; then
  download_filename="$cmdline_filename"
elif test "x$cmdline_dl_dir" != "x"; then
  download_filename="$cmdline_dl_dir/$filename"
else
  download_filename="$tmp_dir/$filename"
fi

# ensure the parent directory where to download the installer always exists
download_dir=`dirname $download_filename`
(umask 077 && mkdir -p $download_dir) || exit 1

# check if we have that file locally available and if so verify the checksum
cached_file_available="false"
verify_checksum="true"
if test -f $download_filename; then
  echo "$download_filename exists"
  if test "x$download_url_override" != "x"; then
    echo "Download URL override detected"
    if test "x$checksum" = "x"; then
      verify_checksum="false"
      echo "checksum not specified, cached file ignored."
    elif do_checksum "$download_filename" "$checksum"; then
      echo "checksum compare succeeded, using existing file!"
      cached_file_available="true"
    else
      checksum_mismatch
    fi
  elif do_checksum "$download_filename" "$sha256"; then
    echo "checksum compare succeeded, using existing file!"
    cached_file_available="true"
  else
    verify_checksum="false"
    echo "checksum mismatch, downloading latest version of the file"
  fi
fi

# download if no local version of the file available or checksum mismatch
if test "x$cached_file_available" != "xtrue"; then
  do_download "$download_url"  "$download_filename"
  if test "x$verify_checksum" = "xtrue"; then
    do_checksum "$download_filename" "$sha256" || checksum_mismatch
  fi
fi

############
# end of fetch_package.sh
############
