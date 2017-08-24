describe package("Chef Client v13*") do
  it { should be_installed }
  its('version') { should match /13.2.20/ }
end

# redirect verbose output
describe command("powershell.exe -file /tmp/install_with_checksum.ps1 *>&1") do
  its("stdout") { should match /Found existing installer/ }
  its("stdout") { should match /Checksum verified, using existing installer/ }
end
