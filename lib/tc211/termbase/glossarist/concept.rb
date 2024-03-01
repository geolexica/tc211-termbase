module Tc211::Termbase
  module Glossarist
    class Concept < ::Glossarist::LocalizedConcept
      attr_accessor :status, :dateAccepted

      def uuid
        @uuid ||= ::Glossarist::Utilities::UUID.uuid_v5(
          ::Glossarist::Utilities::UUID::OID_NAMESPACE,
          to_h(only_data: true).to_yaml,
        )
      end

      def to_h(only_data: false)
        date_accepted = dates.find(&:accepted?)

        data_hash = super()
        return data_hash if only_data

        data_hash.merge({
          "dateAccepted" => date_accepted&.date&.dup,
          "id" => uuid,
          "status" => entry_status,
        }.compact)
      end
    end
  end
end
