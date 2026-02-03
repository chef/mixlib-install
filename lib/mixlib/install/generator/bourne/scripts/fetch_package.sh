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
if [ -n "$license_id" ]; then
  # Use content-disposition to get the filename
  use_content_disposition="true"
  # We don't know the filename yet - it will come from Content-Disposition
  # Just set the download directory
  if [ -n "$cmdline_filename" ]; then
    download_filename="$cmdline_filename"
    download_dir=`dirname $download_filename`
    use_content_disposition="false"  # User specified exact filename
  elif [ -n "$cmdline_dl_dir" ]; then
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
  if [ -n "$cmdline_filename" ]; then
    download_filename="$cmdline_filename"
  elif [ -n "$cmdline_dl_dir" ]; then
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
if [ "$use_content_disposition" = "true" ]; then
  cached_file_available="false"
  verify_checksum="true"
elif [ -n "$download_filename" ] && [ -f "$download_filename" ]; then
  echo "$download_filename exists"
  cached_file_available="true"
fi

if [ -n "$download_url_override" ] && [ "$use_content_disposition" = "false" ]; then
  echo "Download URL override specified"
  if [ "$cached_file_available" = "true" ]; then
    echo "Verifying local file"
    if [ -z "$sha256" ]; then
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
    if [ -z "$sha256" ]; then
      verify_checksum="false" # no checksum to compare after download
    else
      verify_checksum="true" # checksum new downloaded file
    fi
  fi
fi

if [ "$cached_file_available" != "true" ]; then
  if [ "$use_content_disposition" = "true" ]; then
    # For licensed APIs, download to a temporary file and extract filename from response headers
    # The download_dir was already set during initialization above

    # Create temp file for download
    temp_download="$download_dir/chef-download-temp.$$"

    # Download to temp file
    do_download "$download_url" "$temp_download"

    # Extract filename from response headers (try multiple methods for compatibility)
    if [ -f "$tmp_dir/stderr" ]; then
      # Method 1: Try to extract filename from content-disposition header
      # Format: content-disposition: attachment; filename="chef-18.8.54-1.el9.x86_64.rpm"
      actual_filename=`grep -i 'content-disposition' $tmp_dir/stderr | sed -n 's/.*filename="\([^"]*\)".*/\1/p' | head -1`

      # Method 2: If content-disposition failed, try to extract from location redirect header
      # Format: location: https://packages.chef.io/files/stable/chef/18.8.54/el/9/chef-18.8.54-1.el9.x86_64.rpm?licenseId=...
      if [ -z "$actual_filename" ]; then
        actual_filename=`grep -i '^location:' $tmp_dir/stderr | head -1 | sed 's/.*\///' | sed 's/?.*//'`
      fi

      # Method 3: Try extracting from any URL-like pattern in stderr
      if [ -z "$actual_filename" ]; then
        actual_filename=`grep -i '\.rpm\|\.deb\|\.pkg\|\.msi\|\.dmg' $tmp_dir/stderr | sed -n 's/.*\/\([^/?]*\.\(rpm\|deb\|pkg\|msi\|dmg\)\).*/\1/p' | head -1`
      fi
    fi

    # If we still couldn't extract from headers, construct filename from metadata
    if [ -z "$actual_filename" ]; then
      echo "Warning: Could not extract filename from response headers, using fallback"
      # Construct a reasonable filename from available metadata
      # This is a fallback and may not match the exact package name
      if [ "$platform" = "el" ] || [ "$platform" = "fedora" ] || [ "$platform" = "amazon" ]; then
        actual_filename="chef-${version}-1.${platform}${platform_version}.${machine}.rpm"
      elif [ "$platform" = "debian" ] || [ "$platform" = "ubuntu" ]; then
        actual_filename="chef_${version}-1_${machine}.deb"
      elif [ "$platform" = "mac_os_x" ]; then
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

if [ "$verify_checksum" = "true" ]; then
  if [ -z "$sha256" ]; then
    echo "Skipping checksum verification - no checksum provided"
  else
    do_checksum "$download_filename" "$sha256" || checksum_mismatch
  fi
fi

############
# end of fetch_package.sh
############
