# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Domain
    class Invitation
      OPTIONAL_FIELDS = %i[platform opportunity_title compensation engagement_type duration source_url].freeze
      SOURCE_FIELDS = %i[id mailbox_id received_at sender subject excerpt].freeze
      DIRECT_PROVENANCE = {
        evidence_id: :id,
        mailbox_id: :mailbox_id,
        received_at: :received_at,
        sender: :sender,
        subject: :subject,
        source_message_reference: :id
      }.freeze

      attr_reader :evidence, :attributes, :provenance

      def initialize(evidence:, attributes:, provenance:)
        raise InvalidResponse, "invitation requires evidence" unless evidence.is_a?(Evidence)

        @evidence = evidence
        @attributes = normalize_attributes(attributes)
        @provenance = normalize_provenance(provenance, @attributes)
        freeze
      end

      def to_h
        base_payload.merge(attributes).merge(provenance: complete_provenance)
      end

      def inspect
        "#<PrismMail::Domain::Invitation [redacted]>"
      end

      private

      def base_payload
        {
          schema_version: "prism-mail.invitation.v1",
          evidence_id: evidence.id,
          mailbox_id: evidence.mailbox_id,
          received_at: evidence.received_at.iso8601,
          sender: evidence.sender,
          subject: evidence.subject,
          source_message_reference: evidence.id
        }
      end

      def normalize_attributes(value)
        raise InvalidResponse, "invalid invitation attributes" unless value.is_a?(Hash)

        value.each_with_object({}) do |(key, field_value), result|
          raise InvalidResponse, "unsupported invitation field" unless OPTIONAL_FIELDS.include?(key)
          raise InvalidResponse, "invalid invitation field" unless field_value.is_a?(String) && !field_value.empty?

          result[key] = field_value.dup.freeze
        end.freeze
      end

      def normalize_provenance(value, normalized_attributes)
        raise InvalidResponse, "invalid invitation provenance" unless value.is_a?(Hash)
        unless value.keys.sort == normalized_attributes.keys.sort
          raise InvalidResponse, "every extracted invitation field requires provenance"
        end

        value.each_with_object({}) do |(key, entry), result|
          result[key] = normalize_provenance_entry(entry)
        end.freeze
      end

      def normalize_provenance_entry(entry)
        validate_provenance_entry(entry)
        source_field = entry.fetch(:source_field)
        rule = entry.fetch(:rule)

        { evidence_id: evidence.id, source_field: source_field.to_s.freeze,
          rule: rule.dup.freeze }.freeze
      end

      def validate_provenance_entry(entry)
        valid_shape = entry.is_a?(Hash) && entry.keys.sort == %i[rule source_field]
        raise InvalidResponse, "invalid invitation provenance entry" unless valid_shape

        valid_source = SOURCE_FIELDS.include?(entry[:source_field])
        valid_rule = entry[:rule].is_a?(String) && !entry[:rule].empty?
        return if valid_source && valid_rule

        raise InvalidResponse, "invalid invitation provenance entry"
      end

      def complete_provenance
        DIRECT_PROVENANCE.each_with_object({}) do |(field, source_field), result|
          result[field] = { evidence_id: evidence.id, source_field: source_field.to_s }.freeze
        end.merge(provenance).freeze
      end
    end
  end
end
