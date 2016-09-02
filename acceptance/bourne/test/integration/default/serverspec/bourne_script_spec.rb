require "mixlib/install"

describe "install.sh" do
  it "should install" do
     `Mixlib::Install.install_sh`
  end
end
