# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "uri"

module PrismMail
  module Signals
    class UpworkInvitationDetector
      SUBJECT_PATTERNS = [
        /\binvitation to interview\b/i,
        /\binvited you to (?:interview|apply)\b/i,
        /\bjob invitation\b/i
      ].freeze

      TITLE_PATTERNS = [
        /\binvitation to interview\b\s*(?:for\s*)?[:\-–—]\s*(?<title>.+)\z/i,
        /\binvited you to (?:interview|apply)\b\s*(?:for\s*)?[:\-–—]\s*(?<title>.+)\z/i,
        /\bjob invitation\b\s*[:\-–—]\s*(?<title>.+)\z/i
      ].freeze

      def call(evidence:)
        raise InvalidResponse, "signal detector requires evidence" unless evidence.is_a?(Domain::Evidence)
        return unless upwork_domain?(sender_domain(evidence.sender))
        return unless SUBJECT_PATTERNS.any? { |pattern| evidence.subject.match?(pattern) }

        attributes = { platform: "upwork" }
        provenance = { platform: { source_field: :sender, rule: "sender_domain" } }
        add_title(attributes, provenance, evidence.subject)
        add_source_url(attributes, provenance, evidence.excerpt)

        Domain::Invitation.new(evidence: evidence, attributes: attributes, provenance: provenance)
      end

      private

      def sender_domain(sender)
        address = sender_address(sender)
        parts = address.split("@", -1)
        return unless parts.length == 2 && parts.none?(&:empty?)
        return unless address.split.length == 1

        parts.last.downcase
      end

      def sender_address(sender)
        value = sender.strip
        opening = value.rindex("<")
        return value unless opening && value.end_with?(">")

        value[(opening + 1)...-1].strip
      end

      def upwork_domain?(domain)
        domain == "upwork.com" || domain&.end_with?(".upwork.com")
      end

      def add_title(attributes, provenance, subject)
        match = TITLE_PATTERNS.filter_map { |pattern| subject.match(pattern) }.first
        return unless match

        title = match[:title].strip
        return if title.empty?

        attributes[:opportunity_title] = title
        provenance[:opportunity_title] = { source_field: :subject, rule: "subject_pattern" }
      end

      def add_source_url(attributes, provenance, excerpt)
        url = URI::DEFAULT_PARSER.extract(excerpt, %w[https http]).find do |candidate|
          uri = URI.parse(candidate)
          uri.is_a?(URI::HTTPS) && upwork_domain?(uri.host&.downcase)
        rescue URI::InvalidURIError
          false
        end
        return unless url

        attributes[:source_url] = url
        provenance[:source_url] = { source_field: :excerpt, rule: "https_url_host" }
      end
    end
  end
end
