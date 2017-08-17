describe package("chef") do
  it { should be_installed }
end

describe command("/tmp/install.sh") do
  its("stdout") { should match "Nothing to install" }
end
