module Tc211
  module Termbase
    module Glossarist
      class ManagedConcept < ::Glossarist::ManagedConcept
        attr_accessor :status

        def uuid
          @uuid ||= ::Glossarist::Utilities::UUID.uuid_v5(
            ::Glossarist::Utilities::UUID::OID_NAMESPACE,
            to_h(only_data: true).to_yaml,
          )
        end

        def to_h(only_data: false)
          data_hash = super()
          return data_hash if only_data

          data_hash.merge(register_info)
        end

        def register_info
          date_accepted = default_lang.dates.find(&:accepted?)

          {
            "dateAccepted" => date_accepted&.date&.dup,
            "id" => uuid,
            "related" => related&.map(&:to_h) || [],
            "status" => default_lang.entry_status,
          }.compact
        end
      end
    end
  end
end
