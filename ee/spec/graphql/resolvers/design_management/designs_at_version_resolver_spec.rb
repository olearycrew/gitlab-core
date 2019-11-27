# frozen_string_literal: true

require "spec_helper"

describe Resolvers::DesignManagement::DesignsAtVersionResolver do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  set(:issue) { create(:issue) }
  set(:project) { issue.project }

  set(:design_a) { create(:design, issue: issue) }
  set(:design_b) { create(:design, issue: issue) }
  set(:design_c) { create(:design, issue: issue) }
  set(:design_d) { create(:design, issue: issue) }

  set(:first_version) do
    create(:design_version, issue: issue,
           created_designs: [design_a],
           modified_designs: [],
           deleted_designs: [])
  end
  set(:second_version) do
    create(:design_version, issue: issue,
           created_designs: [design_b, design_c, design_d],
           modified_designs: [design_a],
           deleted_designs: [])
  end
  set(:third_version) do
    create(:design_version, issue: issue,
           created_designs: [],
           modified_designs: [design_a],
           deleted_designs: [design_d])
  end

  before do
    enable_design_management
  end

  describe "#resolve" do
    set(:current_user) { create(:user) }
    let(:gql_context) { { current_user: current_user } }
    let(:args) { {} }
    let(:version) { third_version }

    before do
      project.add_developer(current_user)
    end

    context "when the user cannot see designs" do
      let(:gql_context) { { current_user: create(:user) } }

      it "returns nothing" do
        expect(resolve_objects).to be_empty
      end
    end

    context "for the current version" do
      it "returns all designs visible at that version" do
        expect(resolve_objects).to contain_exactly(dav(design_a), dav(design_b), dav(design_c))
      end
    end

    context "for a previous version with more objects" do
      let(:version) { second_version }

      it "returns objects that were later deleted" do
        expect(resolve_objects).to contain_exactly(dav(design_a), dav(design_b), dav(design_c), dav(design_d))
      end
    end

    context "for a previous version with fewer objects" do
      let(:version) { first_version }

      it "does not return objects that were later created" do
        expect(resolve_objects).to contain_exactly(dav(design_a))
      end
    end

    describe "filtering" do
      describe "by filename" do
        let(:red_herring) { create(:design, issue: create(:issue, project: project)) }
        let(:args) { { filenames: [design_b.filename, red_herring.filename] } }

        it "resolves to just the relevant design" do
          create(:design, issue: create(:issue, project: project), filename: design_b.filename)

          expect(resolve_objects).to contain_exactly(dav(design_b))
        end
      end

      describe "by id" do
        let(:red_herring) { create(:design, issue: create(:issue, project: project)) }
        let(:args) { { ids: [design_a, red_herring].map { |x| to_id(x) } } }

        it "resolves to just the relevant design, ignoring objects on other issues" do
          expect(resolve_objects).to contain_exactly(dav(design_a))
        end
      end
    end
  end

  def resolve_objects
    resolve(described_class, obj: version, args: args, ctx: gql_context)
  end

  def dav(design)
    ::DesignManagement::DesignAtVersion.new(design: design, version: version)
  end

  def to_id(obj)
    GitlabSchema.id_from_object(obj).to_s
  end
end
