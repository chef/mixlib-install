# Uncomment when re-running for local development
describe command("sudo rm -rf /tmp/metadata /tmp/checksum /tmp/bad; sudo yum remove chef -y") do
  its("exit_status") { should eq 0 }
end

#
# DOWNLOAD URL TESTS
#
# No checksum provided
describe command("sudo /tmp/install.sh") do
  its("stdout") { should match /Download URL override specified/ }
  its("stdout") { should match /tmp\/checksum\/chef.* not found/ }
  its("stdout") { should match /Thank you/ }
end

# Running same script again
describe command("sudo /tmp/install.sh") do
  its("stdout") { should match /Download URL override specified/ }
  its("stdout") { should match /Verifying local file/ }
  its("stdout") { should match /Checksum not specified/ }
  its("stdout") { should match /Thank you/ }
end

# Now with a valid checksum
describe command("sudo /tmp/install_checksum.sh") do
  its("stdout") { should match /Download URL override specified/ }
  its("stdout") { should match /Verifying local file/ }
  its("stdout") { should match /Checksum match/ }
  its("stdout") { should match /Thank you/ }
end

# Corrupt the file we just downloaded
describe command("sudo chown centos /tmp/checksum; sudo chown centos /tmp/checksum/*; for i in /tmp/checksum/*; do echo 'oops'>>$i; done;") do
  its("exit_status") { should eq 0 }
end

# Run with checksum and it should download and re-verify the checksum
describe command("sudo /tmp/install_checksum.sh") do
  its("stdout") { should match /Download URL override specified/ }
  its("stdout") { should match /Verifying local file/ }
  its("stdout") { should match /Checksum mismatch/ }
  its("stdout") { should match /Thank you/ }
end

# clean up
describe command("sudo yum remove chef -y") do
  its("stdout") { should match /Complete!/ }
end

#
# METADATA URL TESTS
#
# Default behavior when specifying a download location (otherwise caching is unavailable)
describe command("sudo /tmp/install_metadata.sh") do
  its("stdout") { should_not match /tmp\/metadata\/chef.* exists/ }
  its("stdout") { should match /Thank you/ }
end

# Running same script again
describe command("sudo /tmp/install_metadata.sh") do
  its("stdout") { should match /tmp\/metadata\/chef.* exists/ }
  its("stdout") { should match /Thank you/ }
end

# clean up
describe command("sudo yum remove chef -y") do
  its("stdout") { should match /Complete!/ }
end

#
# DOWNLOAD URL BAD CHECKSUM TESTS
#
describe command("sudo /tmp/install_bad.sh") do
  its("stdout") { should match /Download URL override specified/ }
  its("stdout") { should match /tmp\/bad\/chef.* not found/ }
  its("stdout") { should match /Package checksum mismatch/ }
  its("exit_status") { should eq 1 }
end
