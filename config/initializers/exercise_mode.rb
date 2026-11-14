# Donburi is a deliberately vulnerable demo application used in an incident
# response training exercise. These settings keep the public deployment safe to
# host: sign-up is gated behind an invite code, the app is never indexed, and a
# non-removable banner is shown on every page.
#
# None of this touches the application's behaviour; it only limits exposure of
# the hosted instance.
module Donburi
  module Exercise
    # Required to sign up. Rotate per event; publish with an expiry.
    INVITE_CODE = ENV.fetch("INVITE_CODE", "dev-invite")

    # Shown in the non-removable banner.
    BANNER_TEXT = ENV.fetch(
      "EXERCISE_BANNER",
      "【訓練用】これはインシデント対応ハンズオンの演習環境です。実在のサービスではありません。"
    )

    def self.invite_code = INVITE_CODE
    def self.banner_text = BANNER_TEXT
  end
end
