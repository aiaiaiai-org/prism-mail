# © 2026 aiaiaiai · aiaiaiai.org
# SPDX-License-Identifier: Apache-2.0

module PrismMail
  module Ports
    # Implement #read(mailbox_id:) and return a complete bounded Enumerable of Evidence.
    # Incomplete scans must raise; an empty collection means a successful empty source.
    class Source
      def read(mailbox_id:)
        raise NotImplementedError, "source must implement read(mailbox_id:)"
      end
    end
  end
end
