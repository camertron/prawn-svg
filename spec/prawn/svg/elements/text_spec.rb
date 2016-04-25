require File.dirname(__FILE__) + '/../../../spec_helper'

describe Prawn::SVG::Elements::Text do
  let(:document) { Prawn::SVG::Document.new(svg, [800, 600], {}, font_registry: Prawn::SVG::FontRegistry.new("Helvetica" => {:normal => nil}, "Courier" => {normal: nil}, 'Times-Roman' => {normal: nil})) }
  let(:element)  { Prawn::SVG::Elements::Text.new(document, document.root, [], fake_state) }

  describe "xml:space preserve" do
    let(:svg) { %(<text#{attributes}>some\n\t  text</text>) }

    context "when xml:space is preserve" do
      let(:attributes) { ' xml:space="preserve"' }

      it "converts newlines and tabs to spaces, and preserves spaces" do
        element.process

        expect(element.calls).to eq [
          ["draw_text", ["some    text", {:size=>16, :style=>:normal, :text_anchor=>'start', :at=>[0.0, 150.0]}], []]
        ]
      end
    end

    context "when xml:space is unspecified" do
      let(:attributes) { '' }

      it "strips space" do
        element.process

        expect(element.calls).to eq [
          ["draw_text", ["some text", {:size=>16, :style=>:normal, :text_anchor=>'start', :at=>[0.0, 150.0]}], []]
        ]
      end
    end
  end

  describe "when text-anchor is specified" do
    let(:svg) { '<g text-anchor="middle" font-size="12"><text x="50" y="14">Text</text></g>' }
    let(:element) { Prawn::SVG::Elements::Container.new(document, document.root, [], fake_state) }

    it "should inherit text-anchor from parent element" do
      element.process
      expect(element.calls.flatten).to include(:size => 12.0, :style => :normal, :text_anchor => "middle", :at => [50.0, 136.0])
    end
  end

  describe "letter-spacing" do
    let(:svg) { '<text letter-spacing="5">spaced</text>' }

    it "calls character_spacing with the requested size" do
      element.process

      expect(element.base_calls).to eq [
        ["fill", [], [
          ["font", ["Helvetica", {style: :normal}], []],
          ["text_group", [], [
            ["character_spacing", [5.0], [
              ["draw_text", ["spaced", {:size=>16, :style=>:normal, :text_anchor=>'start', :at=>[0.0, 150.0]}], []]
            ]]
          ]]
        ]]
      ]
    end
  end

  describe "font finding" do
    context "with a font that exists" do
      let(:svg) { '<text font-family="monospace">hello</text>' }

      it "finds the font and uses it" do
        element.process
        expect(element.base_calls[0][2][0]).to eq ['font', ['Courier', {style: :normal}], []]
      end
    end

    context "with a font that doesn't exist" do
      let(:svg) { '<text font-family="does not exist">hello</text>' }

      it "uses the fallback font" do
        element.process
        expect(element.base_calls[0][2][0]).to eq ['font', ['Times-Roman', {style: :normal}], []]
      end

      context "when there is no fallback font" do
        before { document.font_registry.installed_fonts.delete("Times-Roman") }

        it "doesn't call the font method and logs a warning" do
          element.process
          expect(element.base_calls.flatten).to_not include 'font'
          expect(document.warnings.first).to include "is not a known font"
        end
      end
    end
  end

  describe "<tref>" do
    let(:svg) { '<svg xmlns:xlink="http://www.w3.org/1999/xlink"><defs><text id="ref" fill="green">my reference text</text></defs><text x="10"><tref xlink:href="#ref" fill="red" /></text></svg>' }
    let(:element) { Prawn::SVG::Elements::Root.new(document, document.root, [], fake_state) }

    it "references the text" do
      element.process
      expect(flatten_calls(element.base_calls)[11..15]).to eq [
        ["fill_color", ["ff0000"]],
        ["fill", []],
        ["font", ["Helvetica", {:style=>:normal}]],
        ["character_spacing", [0]],
        ["draw_text", ["my reference text", {:size=>16, :style=>:normal, :text_anchor=>"start", :at=>[10.0, 150.0]}]],
      ]
    end
  end
end
