# rjv-replica-screenshot: worked case

Moved out of SKILL.md so agents do not load it every time.

## Evidence

Bug #3604 (mfstack): SIP "Instalment Details" showed the Upcoming installment
date raw (`2026-08-24 00:00:00`) vs completed `d M y h:i a`. The real SIP detail
page couldn't render in local dev: a pre-existing unrelated broken import in
`SipPage.tsx` left the page blank. So: dumped the real `OrderHistoryReport::groupSipData()`
payload for a real active SIP (`upcoming date = "2026-08-24 00:00:00"`, then after
the fix `"24 Aug 26"`, completed `"09 Jul 26 04:09 pm"` unchanged), rebuilt the
`SIPInstalmentRow` layout in HTML with those exact strings, screenshotted
before/after, and labeled both as payload-rendered. The reviewer (cross-vendor)
signed off on the fix on payload evidence; the images communicated it visually
without ever pretending to be a live screen.

The rule this case set (labeled replica of real data is evidence; unlabeled
or invented is fabricated) lives in SKILL.md under the honesty contract.
