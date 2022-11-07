# frozen_string_literal: true

describe DiscourseChatMatrix::ChatMatrixController do
  before { DiscourseChatMatrixHelpers.enable! }

  describe "#well_known" do
    it "returns the homeserver URL" do
      # When
      get "/.well-known/matrix/client"

      # Then
      expect(response.status).to eq(200)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
      expect(response.headers["Access-Control-Allow-Methods"]).to eq(
        "GET, POST, PUT, DELETE, OPTIONS",
      )
      expect(response.headers["Access-Control-Allow-Headers"]).to eq(
        "X-Requested-With, Content-Type, Authorization",
      )
      expect(response.parsed_body["m.homeserver"]["base_url"]).to eq(SiteSetting.matrix_homeserver)
    end
  end

  describe "#health" do
    it "returns 200" do
      # When
      get "/matrix/health"

      # Then
      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({})
    end
  end
end
