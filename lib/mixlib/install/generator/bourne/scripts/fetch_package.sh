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
    # For licensed APIs, download to directory and let server provide filename via Content-Disposition
    # The download_dir was already set during initialization above
    
    # Change to download directory for wget --content-disposition to work
    cd "$download_dir"
    do_download "$download_url" ""  # Empty filename - wget will use Content-Disposition
    
    # Find the downloaded file (should be the most recently created file)
    actual_filename=`ls -t "$download_dir" | head -1`
    download_filename="$download_dir/$actual_filename"
    
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
