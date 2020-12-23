require "spec_helper"
require "mixlib/install"
require "mixlib/install/product"

context "With extra distribution Environment variable" do
  let(:mi) do
    with_modified_env(EXTRA_PRODUCTS_FILE: EXTRA_FILE) do
      Mixlib::Install.new(product_name: "cinc", channel: :stable)
    end
  end

  it "Doesn't raise error" do
    expect { mi }.not_to raise_error
  end

  it "Should include cinc as allowed product" do
    expect(mi.options.supported_product_names).to include("cinc")
  end

  it "Should get the product specific URL" do
    expect(PRODUCT_MATRIX.lookup("cinc").api_url).to match("https://packages.cinc.sh")
  end
end
