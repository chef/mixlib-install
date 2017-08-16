describe package("Chef Client v13*") do
  it { should be_installed }
end

describe command("powershell.exe -file /tmp/install.ps1") do
  its("stdout") { should match "Nothing to install" }
end
