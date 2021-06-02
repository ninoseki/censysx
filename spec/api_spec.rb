# frozen_string_literal: true

RSpec.describe Censys::API, :vcr do
  describe "#view" do
    it do
      res = subject.view("1.1.1.1")
      expect(res).to be_a(Hash)
    end

    context "with at_time" do
      let(:at_time) { "2021-06-01T00:00:00.000000Z" }

      it do
        res = subject.view("1.1.1.1", at_time: at_time)
        expect(res).to be_a(Hash)
      end
    end
  end

  describe "#search" do
    let(:query) { 'services.http.response.body_hash:"sha1:4a3ce8ee11e091dd7923f4d8c6e5b5e41ec7c047"' }

    it do
      res = subject.search(query)
      expect(res).to be_a(Hash)

      links = res.dig("result", "links")
      expect(links["next"]).not_to eq("")
      expect(links["prev"]).to eq("")
    end

    context "with cursor" do
      let(:cursor) { "eyJBZnRlciI6WyIxNC4yMTg5NzUiLCIzNy4xODcuOTguMTY1Il0sIlJldmVyc2UiOmZhbHNlfQ==" }

      it do
        res = subject.search(query, cursor: cursor)
        expect(res).to be_a(Hash)

        links = res.dig("result", "links")
        expect(links["prev"]).not_to eq("")
      end
    end
  end

  describe "#aggregate" do
    let(:query) { 'services.http.response.body_hash:"sha1:4a3ce8ee11e091dd7923f4d8c6e5b5e41ec7c047"' }
    let(:field) { "location.continent" }

    it do
      res = subject.aggregate(query, field)
      expect(res).to be_a(Hash)
    end

    context "with num_bucket" do
      let(:num_buckets) { 1 }

      it do
        res = subject.aggregate(query, field, num_buckets: num_buckets)
        expect(res).to be_a(Hash)

        buckets = res.dig("result", "buckets")
        expect(buckets.length).to eq(num_buckets)
      end
    end
  end
end
