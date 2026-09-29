require "spec_helper"
require "mixlib/install"
require "mixlib/install/product"

RSpec.describe "With extra distribution Environment variable" do
  let(:mi) do
    with_modified_env(EXTRA_PRODUCTS_FILE: EXTRA_FILE) do
      Mixlib::Install.new(product_name: "cinc", channel: :stable)
    end
  end

  # Loading EXTRA_PRODUCTS_FILE adds products to the global PRODUCT_MATRIX.
  # Restore it afterwards so examples elsewhere see only the built-in products
  # regardless of run order.
  around do |example|
    product_map = PRODUCT_MATRIX.instance_variable_get(:@product_map).dup
    begin
      example.run
    ensure
      PRODUCT_MATRIX.instance_variable_set(:@product_map, product_map)
    end
  end

  it "Doesn't raise error" do
    expect { mi }.not_to raise_error
  end

  it "Should include cinc as allowed product" do
    expect(mi.options.supported_product_names).to include("cinc")
  end

  it "Should get the product specific URL" do
    mi
    expect(PRODUCT_MATRIX.lookup("cinc").api_url).to match("https://packages.cinc.sh")
  end
end
