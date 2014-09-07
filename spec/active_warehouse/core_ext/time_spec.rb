require 'spec_helper'

describe Time, "core extension" do
  describe "#week" do
    it "returns the correct week" do
      expect(Time.parse('2005-01-01').week).to eq(1)
      expect(Time.parse('2005-12-30').week).to eq(52)
    end
  end

  describe "#quarter" do
    it "returns the correct quarter" do
      expect(Time.parse('2005-01-01').quarter).to eq(1)
      expect(Time.parse('2005-12-30').quarter).to eq(4)
    end
  end

  describe "#fiscal_year_week" do
    it "returns the correct fiscal year week" do
      expect(Time.parse('2005-10-01').fiscal_year_week).to eq(1) 
      expect(Time.parse('2005-11-01').fiscal_year_week).to eq(5)
    end

    context "with a specific offset" do
      it "returns the correct fiscal year week" do
        expect(Time.parse('2006-07-01').fiscal_year_week(7)).to eq(1)
      end
    end
  end

  describe "#fiscal_year_month" do
    it "returns the correct fiscal year month" do
      expect(Time.parse('2006-10-10').fiscal_year_month).to eq(1)
      expect(Time.parse('2006-11-01').fiscal_year_month).to eq(2)
    end

    context "with a specific offset" do
      it "returns the correct fiscal year month" do
        expect(Time.parse('2006-07-10').fiscal_year_month(7)).to eq(1)
      end
    end
  end

  describe "#fiscal_year_quarter" do
    it "returns the correct fiscal year quarter" do
      expect(Time.parse('2005-10-01').fiscal_year_quarter).to eq(1)
      expect(Time.parse('2005-12-31').fiscal_year_quarter).to eq(1)
      expect(Time.parse('2006-01-01').fiscal_year_quarter).to eq(2)
      expect(Time.parse('2006-04-01').fiscal_year_quarter).to eq(3)
    end

    context "with a specific offset" do
      it "returns the correct fiscal year quarter" do
        expect(Time.parse('2006-07-01').fiscal_year_quarter(7)).to eq(1)
      end
    end
  end

  describe "#fiscal_year" do
    it "returns the correct fiscal year" do
      expect(Time.parse('2005-10-01').fiscal_year).to eq(2006)
      expect(Time.parse('2005-12-31').fiscal_year).to eq(2006)
      expect(Time.parse('2006-01-01').fiscal_year).to eq(2006)
      expect(Time.parse('2006-10-10').fiscal_year).to eq(2007)
    end

    context "with a specific offset" do
      it "returns the correct fiscal year" do
        expect(Time.parse('2005-07-01').fiscal_year(7)).to eq(2006)
      end
    end
  end

  describe "#fiscal_year_yday" do
    it "returns the correct year of day for the fiscal year" do
      expect(Time.parse('2005-10-01').fiscal_year_yday).to eq(1)
      expect(Time.parse('2006-09-30').fiscal_year_yday).to eq(365)
    end
  end
end

