# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  class Error < StandardError; end
  class InvalidInput < Error; end
  class InvalidResponse < Error; end
  class AccessDenied < Error; end
  class SourceUnavailable < Error; end
  class RateLimited < SourceUnavailable; end
  class SourceLimitExceeded < Error; end
end
