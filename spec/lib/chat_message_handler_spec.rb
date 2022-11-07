# frozen_string_literal: true

describe DiscourseChatMatrix::ChatMessageHandler do
  fab!(:chat_channel) { Fabricate(:chat_channel) }
  fab!(:user) { Fabricate(:user, username: "foo") }

  before { DiscourseChatMatrixHelpers.enable! }

  describe "#on_create" do
    before do
      # Initial server discovery
      stub_request(:get, "https://homeserver.discourse.org/_matrix/client/versions").to_return(
        status: 200,
        body: {
          versions: %w[r0.0.1 r0.1.0 r0.2.0 r0.3.0 r0.4.0 r0.5.0 r0.6.0 r0.6.1 v1.1 v1.2],
          unstable_features: {
            "org.matrix.label_based_filtering": true,
            "org.matrix.e2e_cross_signing": true,
            "org.matrix.msc2432": true,
            "uk.half-shot.msc2666.mutual_rooms": true,
            "io.element.e2ee_forced.public": false,
            "io.element.e2ee_forced.private": false,
            "io.element.e2ee_forced.trusted_private": false,
            "org.matrix.msc3026.busy_presence": false,
            "org.matrix.msc2285.stable": true,
            "org.matrix.msc3827.stable": true,
            "org.matrix.msc2716": false,
            "org.matrix.msc3030": false,
            "org.matrix.msc3440.stable": true,
            "fi.mau.msc2815": false,
          },
        }.to_json,
      )

      # Register user
      stub_request(:post, "https://homeserver.discourse.org/_matrix/client/v3/register").with(
        query: {
          kind: "user",
        },
        body: {
          type: "m.login.application_service",
          username: "foo-d",
        },
      ).to_return(
        status: 200,
        body: {
          user_id: "@foo-d:matrix.discourse.org",
          home_server: "matrix.discourse.org",
          access_token: "syt_YnJ1Y2UxLWQ_VEFTTyeNZfwBNfPizkvc_1phJBH",
          device_id: "WZHKQHTCPG",
        }.to_json,
      )

      # Update user's display name
      stub_request(
        :put,
        "https://homeserver.discourse.org/_matrix/client/v3/profile/@foo-d:matrix.discourse.org/displayname",
      ).with(
        query: {
          user_id: "@foo-d:matrix.discourse.org",
        },
        body: {
          displayname: "foo",
        },
      ).to_return(status: 200, body: {}.to_json)

      # Create room
      stub_request(:post, "https://homeserver.discourse.org/_matrix/client/v3/createRoom").with(
        body: {
          visibility: "public",
          room_alias_name: "#{chat_channel.name.strip.downcase.gsub(/(\s|_)+/, "-")}-d",
          name: chat_channel.name,
          is_direct: false,
        },
      ).to_return(
        status: 200,
        body: {
          room_id: "!TfCluAdYtDPKHONeLP:matrix.discourse.org",
          room_alias: "#politics-0-d:matrix.discourse.org",
        }.to_json,
      )

      # Join room
      stub_request(
        :post,
        "https://homeserver.discourse.org/_matrix/client/v3/join/!TfCluAdYtDPKHONeLP:matrix.discourse.org",
      ).with(query: { user_id: "@foo-d:matrix.discourse.org" }).to_return(
        status: 200,
        body: { room_id: "!TfCluAdYtDPKHONeLP:matrix.discourse.org" }.to_json,
      )
    end

    it "creates a new message in Matrix" do
      # Given
      send_message_stub =
        stub_request(
          :put,
          Addressable::Template.new(
            "https://homeserver.discourse.org/_matrix/client/v3/rooms/!TfCluAdYtDPKHONeLP:matrix.discourse.org/send/m.room.message/{txnId}?user_id=@foo-d:matrix.discourse.org",
          ),
        ).with(
          body: {
            msgtype: "m.text",
            body: "Hello world!",
            format: "org.matrix.custom.html",
            formatted_body: "<p>Hello world!</p>",
          },
        ).to_return(
          status: 200,
          body: { event_id: "$vh5JvjJ59UTo5FUKc3_AlFeq7Nkisi3gQxZJokb9GXk" }.to_json,
        )

      # When
      chat_message_creator =
        Chat::ChatMessageCreator.create(
          chat_channel: chat_channel,
          user: user,
          content: "Hello world!",
        )

      # Then
      expect(send_message_stub).to have_been_requested
    end
  end
end
