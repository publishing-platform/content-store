require "rails_helper"

describe RouteSet, type: :model do
  describe ".from_content_item" do
    it "constructs a route set from a non-redirect content item" do
      item = build(:content_item, base_path: "/path", rendering_app: "frontend")
      item.routes = [
        { "path" => "/path", "type" => "exact" },
        { "path" => "/path.json", "type" => "exact" },
        { "path" => "/path/subpath", "type" => "prefix" },
      ]
      route_set = described_class.from_content_item(item)
      expect(route_set.is_redirect).to eq(false)
      expect(route_set.is_gone).to eq(false)
      expected_routes = [
        { path: "/path", type: "exact" },
        { path: "/path.json", type: "exact" },
        { path: "/path/subpath", type: "prefix" },
      ]
      expect(route_set.routes).to match_array(expected_routes)
      expect(route_set.gone_routes).to eq([])
      expect(route_set.redirects).to eq([])
    end

    it "constructs a route set from a redirect content item" do
      item = build(:redirect_content_item, base_path: "/path")
      item.redirects = [
        { "path" => "/path", "type" => "exact", "destination" => "/somewhere" },
        { "path" => "/path/foo", "type" => "prefix", "destination" => "/somewhere-else" },
      ]

      route_set = described_class.from_content_item(item)
      expect(route_set.is_redirect).to eq(true)
      expect(route_set.routes).to eq([])
      expect(route_set.gone_routes).to eq([])
      expected_redirects = [
        { path: "/path", type: "exact", destination: "/somewhere" },
        { path: "/path/foo", type: "prefix", destination: "/somewhere-else" },
      ]
      expect(route_set.redirects).to match_array(expected_redirects)
    end

    it "constructs a route set from a gone content item" do
      item = build(:gone_content_item, base_path: "/path")
      item.routes = [
        { "path" => "/path", "type" => "exact" },
        { "path" => "/path.json", "type" => "exact" },
        { "path" => "/path/subpath", "type" => "prefix" },
      ]

      route_set = described_class.from_content_item(item)

      expect(route_set.is_gone).to eq(true)
      expected_routes = [
        { path: "/path", type: "exact" },
        { path: "/path.json", type: "exact" },
        { path: "/path/subpath", type: "prefix" },
      ]
      expect(route_set.routes).to eq([])
      expect(route_set.gone_routes).to match_array(expected_routes)
      expect(route_set.redirects).to eq([])
    end

    it "constructs a route set from a gone content item with nil redirects" do
      item = build(:gone_content_item, base_path: "/path", redirects: nil)
      item.routes = [
        { "path" => "/path", "type" => "exact" },
        { "path" => "/path.json", "type" => "exact" },
        { "path" => "/path/subpath", "type" => "prefix" },
      ]

      route_set = described_class.from_content_item(item)

      expect(route_set.is_gone).to eq(true)
      expected_routes = [
        { path: "/path", type: "exact" },
        { path: "/path.json", type: "exact" },
        { path: "/path/subpath", type: "prefix" },
      ]
      expect(route_set.routes).to eq([])
      expect(route_set.gone_routes).to match_array(expected_routes)
      expect(route_set.redirects).to eq([])
    end
  end

  describe "#register!" do
    let(:route_set) { described_class.new(base_path: "/path", rendering_app: "frontend") }
    let(:router_api) { route_set.router_api }

    context "with a non-redirect route set" do
      before do
        route_set.routes = [
          { path: "/path", type: "exact" },
          { path: "/path/sub/path", type: "prefix" },
        ]
      end

      it "registers all registerable routes" do
        route_set.register!
        assert_routes_registered(
          "frontend",
          [
            ["/path", "exact"],
            ["/path/sub/path", "prefix"],
          ],
        )
      end

      it "registers all registerable routes and redirects" do
        route_set.redirects = [
          { path: "/path.json", type: "exact", destination: "/api/content/path" },
        ]
        route_set.register!
        assert_routes_registered(
          "frontend",
          [
            ["/path", "exact"],
            ["/path/sub/path", "prefix"],
          ],
        )
        assert_redirect_routes_registered([["/path.json", "exact", "/api/content/path"]])
      end
    end

    it "is a no-op with no routes or redirects" do
      route_set = described_class.new(base_path: "/path", rendering_app: "frontend")

      expect_any_instance_of(PublishingPlatformApi::Router).not_to receive(:add_route)

      route_set.register!
    end

    it "registers all registerable redirects for a redirect item" do
      redirects = [
        { path: "/path", type: "exact", destination: "/new-path" },
        { path: "/path/sub/path", type: "prefix", destination: "/somewhere-else" },
        {
          path: "/path/longer/sub/path",
          type: "prefix",
          destination: "/somewhere-else-2",
          segments_mode: "ignore",
        },
      ]
      route_set = described_class.new(redirects:, base_path: "/path", is_redirect: true)
      route_set.register!
      assert_redirect_routes_registered([["/path", "exact", "/new-path"], ["/path/sub/path", "prefix", "/somewhere-else"], ["/path/longer/sub/path", "prefix", "/somewhere-else-2", "ignore"]])
    end

    it "registers all registerable gone routes for a gone item" do
      route_set = described_class.new(base_path: "/path", rendering_app: "frontend", is_gone: true)
      route_set.gone_routes = [
        { path: "/path", type: "exact" },
        { path: "/path/sub/path", type: "prefix" },
      ]
      route_set.register!
      assert_gone_routes_registered([["/path", "exact"], ["/path/sub/path", "prefix"]])
    end
  end
end
