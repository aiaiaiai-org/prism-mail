# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "net/http"
require "json"
require "uri"

module PrismMail
  module Adapters
    module HQBase
      class HTTP
        Response = Struct.new(:data, :link, keyword_init: true)
        MAX_BYTES = 2 * 1024 * 1024

        def initialize(origin:, token:)
          @origin = validated_origin(origin)
          unless token.is_a?(String) && token.match?(/\A[^[:cntrl:]\s]+\z/)
            raise InvalidInput, "source token is required"
          end

          @token = token.dup.freeze
        rescue URI::InvalidURIError
          raise InvalidInput, "invalid source origin", cause: nil
        end

        def get(parameters)
          uri = @origin.dup
          uri.path = "/api/v1/messages"
          uri.query = URI.encode_www_form(parameters)
          request = Net::HTTP::Get.new(uri)
          request["Authorization"] = "Bearer #{@token}"
          request["Accept"] = "application/json"
          perform(uri, request)
        rescue Timeout::Error, IOError, SystemCallError, SocketError, OpenSSL::SSL::SSLError
          raise SourceUnavailable, "source transport failed", cause: nil
        end

        def inspect
          "#<PrismMail::Adapters::HQBase::HTTP [redacted]>"
        end

        private

        def validated_origin(origin)
          uri = URI(origin)
          clean = !uri.userinfo && !uri.query && !uri.fragment && ["", "/"].include?(uri.path)
          return uri if uri.is_a?(URI::HTTPS) && uri.host && clean

          raise InvalidInput, "source origin must be an HTTPS origin"
        end

        def perform(uri, request)
          Net::HTTP.start(uri.host, uri.port, nil, use_ssl: true, open_timeout: 5,
                                                   read_timeout: 15, write_timeout: 5, max_retries: 0) do |http|
            http.request(request) { |response| return parse_response(response) }
          end
        end

        def parse_response(response)
          check_status(response.code.to_i)
          Response.new(data: JSON.parse(read_body(response)), link: response["link"])
        rescue JSON::ParserError
          raise InvalidResponse, "source returned invalid JSON", cause: nil
        end

        def read_body(response)
          body = +""
          response.read_body do |chunk|
            raise InvalidResponse, "source response exceeds byte limit" if body.bytesize + chunk.bytesize > MAX_BYTES

            body << chunk
          end
          body
        end

        def check_status(status)
          return if status == 200

          case status
          when 401, 403 then raise AccessDenied, "source authorization failed"
          when 429 then raise RateLimited, "source rate limited"
          when 500..599 then raise SourceUnavailable, "source unavailable"
          else raise InvalidResponse, "unexpected source HTTP status"
          end
        end
      end
    end
  end
end
