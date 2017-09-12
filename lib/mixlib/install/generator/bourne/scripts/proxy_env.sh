# All of the download utilities in this script load common proxy env vars.
# If variables are set they will override any existing env vars.
# Otherwise, default proxy env vars will be loaded by the respective
# download utility.

if test "x$https_proxy" != "x"; then
  echo "setting https_proxy: $https_proxy"
  export HTTPS_PROXY=$https_proxy
  export https_proxy=$https_proxy
fi

if test "x$http_proxy" != "x"; then
  echo "setting http_proxy: $http_proxy"
  export HTTP_PROXY=$http_proxy
  export http_proxy=$http_proxy
fi

if test "x$ftp_proxy" != "x"; then
  echo "setting ftp_proxy: $ftp_proxy"
  export FTP_PROXY=$ftp_proxy
  export ftp_proxy=$ftp_proxy
fi

if test "x$no_proxy" != "x"; then
  echo "setting no_proxy: $no_proxy"
  export NO_PROXY=$no_proxy
  export no_proxy=$no_proxy
fi
