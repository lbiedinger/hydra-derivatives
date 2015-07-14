require 'spec_helper'

describe Hydra::Derivatives::RetrieveSourceFileService do

  before(:all) do
    
    # Need a class that: 
    #  1) Allows you to set .uri= (to work with directly_contains)
    #  2) has a metadata_node (to work with directly_contains_one)
    class FileWithMetadata < ActiveFedora::File
      include ActiveFedora::WithMetadata
    end
    
    class ObjectWithBasicContainer < ActiveFedora::Base
      contains "contained_file"
    end

    class DirectContainerObject < ActiveFedora::Base
      directly_contains :files, has_member_relation: ::RDF::URI("http://pcdm.org/use#hasFile"),
        class_name: "FileWithMetadata"
      directly_contains_one :directly_contained_file, through: :files, type: ::RDF::URI("http://pcdm.org/use#OriginalFile")
    end
  end

  subject { described_class.call(object, source_name) }
  
  context "when file is in basic container (default assumption)" do  # alas, we have to support this as the default because all legacy code (and fedora 3 systems) created indirectly contained files
    let(:object)            { ObjectWithBasicContainer.new  }
    let(:content)           { "fake file content (basic container)" }
    let(:source_name)       { 'contained_file' }
    
    before do
      # attaches the file as an indirectly contained object
      object.contained_file.content = content
    end
    it "persists the file to the specified destination on the given object" do
      expect(subject).to eq(object.contained_file)
    end
  end

  context "when file is directly contained" do  # direct containers are more efficient, but most legacy code will have indirect containers
    let(:object)            { DirectContainerObject.new }
    let(:content)           { "fake file content (direct container)" }
    let(:source_name)       { 'directly_contained_file' }
    
    before do
      object.save  # can't build directly contained objects without saving the parent first
      object.build_directly_contained_file
      object.directly_contained_file.content = content
    end
    it "retrieves the file from the specified location on the given object" do
      expect(subject).to eq(object.directly_contained_file)
    end
  end
  
end