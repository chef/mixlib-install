describe command("git --version") do
  its("stdout") { should match "git version" }
end

describe command("ruby --version") do
  its("stdout") { should match "ruby.*[x64-mingw32]" }
end

describe command("gcc --version") do
  its("stdout") { should match "gcc.exe" }
end
