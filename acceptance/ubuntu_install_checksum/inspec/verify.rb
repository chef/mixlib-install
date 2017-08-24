describe package("Chef Client v13*") do
  it { should be_installed }
  its("version") { should match /13.2.20/ }
end

describe command("/tmp/install_with_checksum.sh") do
  its("stdout") { should match /Download URL override detected/ }
  its("stdout") { should match /checksum compare succeeded, using existing file/ }
end
