# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

require "test_helper"
require "minitest/mock"
require "stringio"

class HTTPTest < Minitest::Test
  def with_response(status: "200", body: "[]", &block)
    response = Object.new
    response.define_singleton_method(:code) { status }
    response.define_singleton_method(:read_body) { |&block| block.call(body) }
    response.define_singleton_method(:[]) { |_name| nil }
    session = Object.new
    session.define_singleton_method(:request) do |request, &block|
      raise "not read only" unless request.is_a?(Net::HTTP::Get)

      block.call(response)
    end
    start = lambda do |*_args, **_options, &block|
      block.call(session)
    end
    Net::HTTP.stub(:start, start, &block)
  end

  def client
    PrismMail::Adapters::HQBase::HTTP.new(origin: "https://mail.test", token: "secret")
  end

  def worker_env(**overrides)
    {
      "PRISM_MAIL_MAILBOX_ID" => "box",
      "PRISM_MAIL_SINCE" => "2026-09-10T00:00:00Z",
      "PRISM_MAIL_BEFORE" => "2026-09-11T00:00:00Z",
      "HQBASE_ORIGIN" => "https://mail.test",
      "HQBASE_ACCESS_TOKEN" => "secret"
    }.merge(overrides)
  end

  def test_status_mapping_does_not_echo_provider_body
    { "401" => PrismMail::AccessDenied, "403" => PrismMail::AccessDenied,
      "429" => PrismMail::RateLimited, "503" => PrismMail::SourceUnavailable,
      "302" => PrismMail::InvalidResponse }.each do |status, error|
      with_response(status: status, body: "private mail secret") do
        caught = assert_raises(error) { client.get(mailboxId: "box") }
        refute_includes caught.message, "secret"
      end
    end
  end

  def test_json_and_byte_limits
    ["not json", "x" * (PrismMail::Adapters::HQBase::HTTP::MAX_BYTES + 1)].each do |body|
      with_response(body: body) { assert_raises(PrismMail::InvalidResponse) { client.get({}) } }
    end
    with_response { assert_equal [], client.get({}).data }
  end

  def test_cli_missing_configuration_has_no_stdout_or_secret
    output = StringIO.new
    errors = StringIO.new
    assert_equal 2, PrismMail::CLI.run(env: {}, output: output, errors: errors)
    assert_empty output.string
    assert_equal "configuration_missing", JSON.parse(errors.string).fetch("error")
  end

  def test_cli_end_to_end_defaults_to_digest
    output = StringIO.new
    with_response { assert_equal 0, PrismMail::CLI.run(env: worker_env, output: output, errors: StringIO.new) }
    assert_equal "prism-mail.digest.v1", JSON.parse(output.string).fetch("schema_version")
    refute_includes output.string, "secret"
  end

  def test_cli_invitation_operation_emits_worker_batch
    row = {
      "id" => "message-1",
      "mailboxId" => "box",
      "direction" => "inbound",
      "folder" => "inbox",
      "subject" => "Invitation to interview: Senior iOS Engineer",
      "fromAddress" => "jobs@upwork.com",
      "snippet" => "Review https://www.upwork.com/jobs/123",
      "receivedAt" => "2026-09-10T12:00:00Z"
    }
    output = StringIO.new
    env = worker_env("PRISM_MAIL_OPERATION" => "invitations")

    with_response(body: JSON.generate([row])) do
      assert_equal 0, PrismMail::CLI.run(env: env, output: output, errors: StringIO.new)
    end

    artifact = JSON.parse(output.string)
    assert_equal "prism-mail.invitation-batch.v1", artifact.fetch("schema_version")
    assert_equal 1, artifact.fetch("scanned_count")
    assert_equal 1, artifact.fetch("invitation_count")
    assert_equal "prism-mail.invitation.v1", artifact.fetch("invitations").first.fetch("schema_version")
    refute_includes output.string, "secret"
  end

  def test_cli_rejects_unknown_operation_without_stdout
    output = StringIO.new
    errors = StringIO.new
    status = PrismMail::CLI.run(
      env: worker_env("PRISM_MAIL_OPERATION" => "unknown"),
      output: output,
      errors: errors
    )

    assert_equal 1, status
    assert_empty output.string
    assert_equal "InvalidInput", JSON.parse(errors.string).fetch("error")
  end
end
